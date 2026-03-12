# C:\SSH_Anahtarlari\user_anahtar_yukle.ps1
# Bu script 8-9 sunucudaki "user" hesabına 3 kişinin anahtarını yükler

# Renkler
$Yesil = [char]27 + "[32m"
$Sari = [char]27 + "[33m"
$Kirmizi = [char]27 + "[31m"
$Mavi = [char]27 + "[34m"
$Sifirla = [char]27 + "[0m"

Clear-Host
Write-Host "$Mavi╔════════════════════════════════════════════════╗$Sifirla"
Write-Host "$Mavi║     USER HESABINA TOPLU ANAHTAR YÜKLEME      ║$Sifirla"
Write-Host "$Mavi╚════════════════════════════════════════════════╝$Sifirla"
Write-Host ""

# KONTROLLER
$hataVar = $false

# Klasör kontrolü
if (-not (Test-Path "C:\SSH_Anahtarlari")) {
    Write-Host "$Kirmizi❌ HATA: C:\SSH_Anahtarlari klasörü yok!$Sifirla"
    Write-Host "Oluşturmak için: New-Item -ItemType Directory -Path C:\SSH_Anahtarlari -Force"
    $hataVar = $true
}

# Anahtar dosyalarını kontrol et
$anahtarDosyalari = @{
    "Ali" = "C:\SSH_Anahtarlari\ali.pub"
    "Ayşe" = "C:\SSH_Anahtarlari\ayse.pub"
    "Mehmet" = "C:\SSH_Anahtarlari\mehmet.pub"
}

foreach ($isim in $anahtarDosyalari.Keys) {
    if (-not (Test-Path $anahtarDosyalari[$isim])) {
        Write-Host "$Kirmizi❌ HATA: $isim'in anahtar dosyası yok! ($($anahtarDosyalari[$isim]))$Sifirla"
        $hataVar = $true
    }
}

# Sunucu listesini kontrol et
if (-not (Test-Path "C:\SSH_Anahtarlari\sunucular.txt")) {
    Write-Host "$Kirmizi❌ HATA: sunucular.txt dosyası yok!$Sifirla"
    $hataVar = $true
}

if ($hataVar) {
    Write-Host "$Sari`n📁 GEREKLİ DOSYALAR:$Sifirla"
    Write-Host "  C:\SSH_Anahtarlari\ali.pub"
    Write-Host "  C:\SSH_Anahtarlari\ayse.pub"
    Write-Host "  C:\SSH_Anahtarlari\mehmet.pub"
    Write-Host "  C:\SSH_Anahtarlari\sunucular.txt"
    pause
    exit
}

# ANAHTARLARI OKU
Write-Host "$Sari📂 Anahtarlar okunuyor...$Sifirla"
$anahtarlar = @{}
$anahtarlar["Ali"] = (Get-Content "C:\SSH_Anahtarlari\ali.pub" -Raw).Trim()
$anahtarlar["Ayşe"] = (Get-Content "C:\SSH_Anahtarlari\ayse.pub" -Raw).Trim()
$anahtarlar["Mehmet"] = (Get-Content "C:\SSH_Anahtarlari\mehmet.pub" -Raw).Trim()

Write-Host "$Yesil✅ Anahtarlar okundu:$Sifirla"
Write-Host "   - Ali:    $($anahtarlar["Ali"].Substring(0,50))..."
Write-Host "   - Ayşe:   $($anahtarlar["Ayşe"].Substring(0,50))..."
Write-Host "   - Mehmet: $($anahtarlar["Mehmet"].Substring(0,50))..."

# SUNUCULARI OKU
$sunucular = Get-Content "C:\SSH_Anahtarlari\sunucular.txt" | Where-Object {
    $_ -ne "" -and $_ -notlike "#*"
}
Write-Host "$Sari📡 Sunucular okundu: $($sunucular.Count) sunucu$Sifirla"

# ÖZET GÖSTER
Write-Host ""
Write-Host "$Mavi═══════════ İŞLEM ÖZETİ ═══════════$Sifirla"
Write-Host "Sunucu sayısı: $($sunucular.Count)"
Write-Host "Kişi sayısı: 3 (Ali, Ayşe, Mehmet)"
Write-Host "Hedef kullanıcı: user"
Write-Host "Toplam eklenecek anahtar: $($sunucular.Count * 3)"
Write-Host "$Mavi══════════════════════════════════$Sifirla"
Write-Host ""
Write-Host "$Sari🔐 BAŞLAMAK İÇİN BİR TUŞA BAS... (Ctrl+C iptal)$Sifirla"
pause

# İSTATİSTİK
$toplamSunucu = $sunucular.Count
$suAnkiSunucu = 0
$eklenenSayac = 0
$zatenVarSayac = 0
$hataSayac = 0

# ANA DÖNGÜ - HER SUNUCU İÇİN
foreach ($sunucu in $sunucular) {
    $suAnkiSunucu++
    Write-Host ""
    Write-Host "$Mavi[$suAnkiSunucu/$toplamSunucu] ===== $sunucu =====$Sifirla"
    
    # BAĞLANTI TESTİ
    Write-Host "  📡 Bağlantı test ediliyor... " -NoNewline
    $test = ssh -o ConnectTimeout=5 -o BatchMode=yes "user@$sunucu" "echo OK" 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "$Kirmizi BAŞARISIZ$Sifirla"
        Write-Host "  $Kirmizi✗ $sunucu'ya bağlanılamadı! Atlanıyor...$Sifirla"
        $hataSayac++
        continue
    }
    Write-Host "$Yesil BAŞARILI$Sifirla"
    
    # ÖNCE MEVCUT ANAHTARLARI KONTROL ET (DUPLICATE ÖNLEME)
    Write-Host "  🔍 Mevcut anahtarlar kontrol ediliyor..."
    $mevcutAnahtarlar = ssh "user@$sunucu" "cat ~/.ssh/authorized_keys 2>/dev/null" 2>$null
    
    # HER KİŞİ İÇİN
    foreach ($kisi in $anahtarlar.Keys) {
        $anahtar = $anahtarlar[$kisi]
        Write-Host "  👤 $kisi kontrol ediliyor... " -NoNewline
        
        # BU ANAHTAR ZATEN VAR MI?
        if ($mevcutAnahtarlar -and $mevcutAnahtarlar.Contains($anahtar)) {
            Write-Host "$Sari ZATEN VAR$Sifirla"
            $zatenVarSayac++
            continue
        }
        
        # ANAHTARI EKLE
        Write-Host "$Yesil EKLENİYOR...$Sifirla" -NoNewline
        
        $komut = @"
# Klasörü oluştur (yoksa)
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Anahtarı ekle (eğer yoksa)
echo '$anahtar' >> ~/.ssh/authorized_keys

# Duplicate'leri temizle ve sırala
sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys

# İzinleri düzelt
chmod 600 ~/.ssh/authorized_keys

# Son kontrol
echo "EKLENDI"
"@

        $sonuc = ssh "user@$sunucu" $komut 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$Yesil EKLENDI ✓$Sifirla"
            $eklenenSayac++
            
            # Log'a yaz
            "$(Get-Date) - $sunucu - $kisi eklendi" | Out-File -FilePath "C:\SSH_Anahtarlari\ekleme_log.txt" -Append
        } else {
            Write-Host "$Kirmizi HATA!$Sifirla"
            Write-Host "     Hata: $sonuc"
            $hataSayac++
            
            # Hata log'u
            "$(Get-Date) - $sunucu - $kisi HATA: $sonuc" | Out-File -FilePath "C:\SSH_Anahtarlari\hata_log.txt" -Append
        }
    }
    
    # SON KONTROL - Kaç anahtar var?
    $sonDurum = ssh "user@$sunucu" "cat ~/.ssh/authorized_keys 2>/dev/null | wc -l" 2>$null
    Write-Host "  📊 $sunucu'da toplam $sonDurum anahtar var"
}

# SONUÇ RAPORU
Write-Host ""
Write-Host "$Mavi══════════════════ İŞLEM TAMAMLANDI ══════════════════$Sifirla"
Write-Host "$Yesil✅ Yeni eklenen anahtar: $eklenenSayac$Sifirla"
Write-Host "$Sari⏭️  Zaten var olan: $zatenVarSayac$Sifirla"
Write-Host "$Mavi📊 Toplam işlem: $($eklenenSayac + $zatenVarSayac)$Sifirla"
if ($hataSayac -gt 0) {
    Write-Host "$Kirmizi❌ Hata: $hataSayac$Sifirla"
    Write-Host "   Hatalar için: C:\SSH_Anahtarlari\hata_log.txt"
} else {
    Write-Host "$Yesil✅ Hiç hata yok!$Sifirla"
}
Write-Host "$Mavi════════════════════════════════════════════════════════$Sifirla"
Write-Host ""
Write-Host "$Sari📝 Log dosyaları:$Sifirla"
Write-Host "   - C:\SSH_Anahtarlari\ekleme_log.txt (başarılı eklemeler)"
Write-Host "   - C:\SSH_Anahtarlari\hata_log.txt (varsa hatalar)"
Write-Host ""
Write-Host "$Yesil✅ TEST ET:$Sifirla"
Write-Host "   ssh user@$($sunucular[0])  (şifre sormamalı)"
Write-Host ""
pause