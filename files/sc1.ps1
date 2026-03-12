# SSH ANAHTAR YÜKLEME - TEK SCRIPT
# Yazar: Ali
# Tarih: 2024
# Açıklama: Bu script 20 sunucuya 3 kullanıcının SSH anahtarlarını yükler

# RENKLER
$Yesil = [char]27 + "[32m"
$Sari = [char]27 + "[33m" 
$Kirmizi = [char]27 + "[31m"
$Mavi = [char]27 + "[34m"
$Sifirla = [char]27 + "[0m"

Clear-Host
Write-Host "$Mavi╔════════════════════════════════════════════════╗$Sifirla"
Write-Host "$Mavi║     SSH ANAHTAR TOPLU YÜKLEME SCRIPTİ       ║$Sifirla"
Write-Host "$Mavi╚════════════════════════════════════════════════╝$Sifirla"
Write-Host ""

# KONTROL 1: Anahtar klasörü var mı?
if (-not (Test-Path "C:\SSH_Anahtarlari")) {
    Write-Host "$Kirmizi❌ HATA: C:\SSH_Anahtarlari klasörü bulunamadı!$Sifirla"
    Write-Host "Önce şu klasörü oluştur: C:\SSH_Anahtarlari"
    pause
    exit
}

# KONTROL 2: Sunucu listesi var mı?
if (-not (Test-Path "C:\SSH_Anahtarlari\sunucular.txt")) {
    Write-Host "$Kirmizi❌ HATA: sunucular.txt dosyası bulunamadı!$Sifirla"
    Write-Host "Oluştur: C:\SSH_Anahtarlari\sunucular.txt"
    Write-Host "İçine her satıra bir sunucu IP'si yaz (192.168.1.101 gibi)"
    pause
    exit
}

# KONTROL 3: Anahtar dosyaları var mı?
$anahtarDosyalari = @(
    "C:\SSH_Anahtarlari\kullanici1.pub",
    "C:\SSH_Anahtarlari\kullanici2.pub",
    "C:\SSH_Anahtarlari\kullanici3.pub"
)

$hepsiVar = $true
foreach ($dosya in $anahtarDosyalari) {
    if (-not (Test-Path $dosya)) {
        Write-Host "$Kirmizi❌ HATA: $dosya bulunamadı!$Sifirla"
        $hepsiVar = $false
    }
}
if (-not $hepsiVar) {
    pause
    exit
}

# ANAHTARLARI OKU
Write-Host "$Sari📂 Anahtarlar okunuyor...$Sifirla"
$anahtarlar = @{}
$anahtarlar["kullanici1"] = (Get-Content "C:\SSH_Anahtarlari\kullanici1.pub" -Raw).Trim()
$anahtarlar["kullanici2"] = (Get-Content "C:\SSH_Anahtarlari\kullanici2.pub" -Raw).Trim()
$anahtarlar["kullanici3"] = (Get-Content "C:\SSH_Anahtarlari\kullanici3.pub" -Raw).Trim()
Write-Host "$Yesil✅ Anahtarlar okundu$Sifirla"
Write-Host "   - kullanici1: $(($anahtarlar["kullanici1"].Length).ToString().Substring(0,10))... (ilk 10 karakter)"
Write-Host "   - kullanici2: $(($anahtarlar["kullanici2"].Length).ToString().Substring(0,10))..."
Write-Host "   - kullanici3: $(($anahtarlar["kullanici3"].Length).ToString().Substring(0,10))..."

# SUNUCULARI OKU
$sunucular = Get-Content "C:\SSH_Anahtarlari\sunucular.txt" | Where-Object {$_ -ne "" -and $_ -notlike "#*"}
Write-Host "$Sari📡 Sunucular okundu: $($sunucular.Count) sunucu$Sifirla"

Write-Host ""
Write-Host "$Sari🔐 BAŞLAMAK İÇİN BİR TUŞA BAS... (Ctrl+C iptal)$Sifirla"
pause

# İSTATİSTİK
$toplamSunucu = $sunucular.Count
$toplamKullanici = $anahtarlar.Count
$suAnkiSunucu = 0
$eklenenSayac = 0
$zatenVarSayac = 0
$hataSayac = 0

# HER SUNUCU İÇİN DÖNGÜ
foreach ($sunucu in $sunucular) {
    $suAnkiSunucu++
    Write-Host ""
    Write-Host "$Mavi[$suAnkiSunucu/$toplamSunucu] ===== $sunucu =====$Sifirla"
    
    # BAĞLANTI TESTİ
    Write-Host "  📡 Bağlantı test ediliyor..." -NoNewline
    $test = ssh -o ConnectTimeout=5 -o BatchMode=yes "kullanici1@$sunucu" "echo OK" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "$Kirmizi BAŞARISIZ$Sifirla"
        Write-Host "  $Kirmizi✗ $sunucu'ya bağlanılamadı! Atlanıyor...$Sifirla"
        $hataSayac++
        continue
    }
    Write-Host "$Yesil BAŞARILI$Sifirla"
    
    # HER KULLANICI İÇİN
    foreach ($kullanici in $anahtarlar.Keys) {
        Write-Host "  👤 $kullanici kontrol ediliyor..." -NoNewline
        
        # ANAHTAR VAR MI KONTROL ET
        $kontrol = ssh "kullanici1@$sunucu" "sudo test -f /home/$kullanici/.ssh/authorized_keys && sudo cat /home/$kullanici/.ssh/authorized_keys | grep -F '$($anahtarlar[$kullanici])' || echo 'YOK'" 2>$null
        
        if ($kontrol -like "ssh-rsa*") {
            # Anahtar zaten var
            Write-Host "$Sari ZATEN VAR$Sifirla"
            $zatenVarSayac++
        } else {
            # Anahtar yok, ekle
            Write-Host "$Yesil EKLENİYOR...$Sifirla" -NoNewline
            
            $ekle = ssh "kullanici1@$sunucu" @"
sudo mkdir -p /home/$kullanici/.ssh
echo '$($anahtarlar[$kullanici])' | sudo tee -a /home/$kullanici/.ssh/authorized_keys > /dev/null
sudo sort -u /home/$kullanici/.ssh/authorized_keys -o /home/$kullanici/.ssh/authorized_keys
sudo chown -R $kullanici:$kullanici /home/$kullanici/.ssh
sudo chmod 700 /home/$kullanici/.ssh
sudo chmod 600 /home/$kullanici/.ssh/authorized_keys
echo "EKLENDI"
"@ 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$Yesil EKLENDI ✓$Sifirla"
                $eklenenSayac++
            } else {
                Write-Host "$Kirmizi HATA!$Sifirla"
                $hataSayac++
            }
        }
    }
}

# SONUÇ RAPORU
Write-Host ""
Write-Host "$Mavi══════════════════ İŞLEM TAMAMLANDI ══════════════════$Sifirla"
Write-Host "$Yesil✅ Yeni eklenen anahtar sayısı: $eklenenSayac$Sifirla"
Write-Host "$Sari⏭️  Zaten var olan anahtar sayısı: $zatenVarSayac$Sifirla"
if ($hataSayac -gt 0) {
    Write-Host "$Kirmizi❌ Hata oluşan işlem sayısı: $hataSayac$Sifirla"
} else {
    Write-Host "$Yesil✅ Hiç hata yok!$Sifirla"
}
Write-Host "$Mavi════════════════════════════════════════════════════════$Sifirla"
Write-Host ""
Write-Host "Test etmek için: ssh kullanici1@192.168.1.101"
pause