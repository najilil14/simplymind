// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'SimplyMind';

  @override
  String get cancel => 'Batal';

  @override
  String get create => 'Buat';

  @override
  String get rename => 'Ubah nama';

  @override
  String get delete => 'Hapus';

  @override
  String get save => 'Simpan';

  @override
  String get done => 'Selesai';

  @override
  String get reset => 'Atur ulang';

  @override
  String get duplicate => 'Duplikat';

  @override
  String get dismiss => 'Tutup';

  @override
  String get more => 'Lainnya';

  @override
  String get language => 'Bahasa';

  @override
  String get languageSystem => 'Ikuti sistem';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get importJson => 'Impor JSON';

  @override
  String get exportJson => 'Ekspor JSON';

  @override
  String get exportPng => 'Ekspor gambar (PNG)';

  @override
  String get exportPdf => 'Ekspor PDF';

  @override
  String get exportTooltip => 'Ekspor';

  @override
  String get exportedJson => 'Mindmap diekspor sebagai JSON';

  @override
  String get exportedPng => 'Mindmap diekspor sebagai PNG';

  @override
  String get exportedPdf => 'Mindmap diekspor sebagai PDF';

  @override
  String get exportImageFailed => 'Tidak dapat mengekspor gambar';

  @override
  String get exportPdfFailed => 'Tidak dapat mengekspor PDF';

  @override
  String get newMindMap => 'Mindmap baru';

  @override
  String get createMindMap => 'Buat mindmap';

  @override
  String get renameMindMap => 'Ubah nama mindmap';

  @override
  String deleteMindMapTitle(String title) {
    return 'Hapus \"$title\"?';
  }

  @override
  String get deleteCannotUndo => 'Tindakan ini tidak dapat dibatalkan.';

  @override
  String get titleLabel => 'Judul';

  @override
  String get titleHint => 'mis. Brainstorm proyek';

  @override
  String get template => 'Template';

  @override
  String get noMindMapsYet => 'Belum ada mindmap';

  @override
  String get noMindMapsHint =>
      'Buat mindmap pertama Anda dan mulai kembangkan ide.';

  @override
  String importedMap(String title) {
    return '\"$title\" berhasil diimpor';
  }

  @override
  String get importInvalid => 'File itu bukan mindmap yang valid.';

  @override
  String nodeCount(int count) {
    return '$count node';
  }

  @override
  String nodeCountPlural(int count) {
    return '$count node';
  }

  @override
  String todayAt(String time) {
    return 'Hari ini $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Kemarin $time';
  }

  @override
  String get categoryAll => 'Semua';

  @override
  String get categoryHome => 'Beranda';

  @override
  String get categoryNew => 'Baru';

  @override
  String get newCategory => 'Kategori baru';

  @override
  String get renameCategory => 'Ubah nama kategori';

  @override
  String get categoryName => 'Nama kategori';

  @override
  String get categoryHint => 'mis. Kerja, Pribadi';

  @override
  String get createCategory => 'Buat kategori';

  @override
  String get moveToCategory => 'Pindah ke kategori';

  @override
  String get homeReserved =>
      '\"Home\" dicadangkan untuk mindmap tanpa kategori';

  @override
  String get homeReservedShort => '\"Home\" dicadangkan';

  @override
  String categoryExists(String name) {
    return 'Kategori \"$name\" sudah ada';
  }

  @override
  String deleteCategoryTitle(String name) {
    return 'Hapus \"$name\"?';
  }

  @override
  String get deleteCategoryBody =>
      'Mindmap dalam kategori ini dipindah kembali ke Beranda. Mindmap-nya sendiri tidak dihapus.';

  @override
  String renameCategoryItem(String name) {
    return 'Ubah nama \"$name\"';
  }

  @override
  String deleteCategoryItem(String name) {
    return 'Hapus \"$name\"';
  }

  @override
  String get organizeMapsTitle => 'Atur mindmap Anda?';

  @override
  String organizeMapsBody(int count) {
    return 'Anda memiliki lebih dari $count mindmap. Buat kategori agar lebih rapi.';
  }

  @override
  String get notNow => 'Nanti saja';

  @override
  String noMapsInCategory(String name) {
    return 'Tidak ada mindmap di $name';
  }

  @override
  String get noMapsInCategoryHint =>
      'Buat mindmap baru di sini, atau pindahkan yang sudah ada ke kategori ini.';

  @override
  String get sendFeedback => 'Kirim masukan';

  @override
  String get privacyPolicy => 'Kebijakan Privasi';

  @override
  String get dmca => 'DMCA';

  @override
  String lastUpdated(String date) {
    return 'Terakhir diperbarui: $date';
  }

  @override
  String get feedbackPrefill =>
      'Saya memakai SimplyMind dan punya masukan untuk Anda: ';

  @override
  String whatsAppFailed(String url, String number) {
    return 'Tidak dapat membuka WhatsApp. Buka $url secara manual, atau pesan $number.';
  }

  @override
  String get layoutMap => 'Mindmap';

  @override
  String get layoutList => 'Daftar';

  @override
  String get layoutStep => 'Langkah';

  @override
  String get layoutGraph => 'Grafik';

  @override
  String get layoutMapDesc => 'Posisi bebas dengan menyeret';

  @override
  String get layoutListDesc => 'Garis besar berindentasi, atas ke bawah';

  @override
  String get layoutStepDesc => 'Urutan bernomor dengan panah';

  @override
  String get layoutGraphDesc => 'Cabang radial mengelilingi node';

  @override
  String get layoutInherit => 'Ikuti induk';

  @override
  String get layoutInheritDesc => 'Ikuti template mindmap';

  @override
  String get statusNone => 'Tanpa status';

  @override
  String get statusInProgress => 'Sedang dikerjakan';

  @override
  String get statusDone => 'Selesai';

  @override
  String get undo => 'Urungkan';

  @override
  String get redo => 'Ulangi';

  @override
  String get mapSettings => 'Pengaturan mindmap';

  @override
  String nodePaddingLabel(int px) {
    return 'Padding node: $px px';
  }

  @override
  String get nodePaddingHelp =>
      'Jarak antara teks dan kotak node. Perubahan ditampilkan langsung dan disimpan bersama mindmap ini.';

  @override
  String get focusMode => 'Mode fokus';

  @override
  String get showControls => 'Tampilkan kontrol';

  @override
  String get editNode => 'Edit node';

  @override
  String get newNode => 'Node baru';

  @override
  String get newIdea => 'Ide baru';

  @override
  String get nodeColor => 'Warna node';

  @override
  String get customColor => 'Warna kustom';

  @override
  String get useCustomColor => 'Gunakan warna kustom';

  @override
  String get nodeStatus => 'Status node';

  @override
  String get branchTemplate => 'Template cabang';

  @override
  String get addChild => 'Tambah anak';

  @override
  String get moveLeft => 'Geser kiri';

  @override
  String get moveUp => 'Geser atas';

  @override
  String get moveRight => 'Geser kanan';

  @override
  String get moveDown => 'Geser bawah';

  @override
  String get promote => 'Naikkan (saudara dari induk)';

  @override
  String get status => 'Status';

  @override
  String get color => 'Warna';

  @override
  String get deleteBranch => 'Hapus cabang';

  @override
  String get zoomIn => 'Perbesar';

  @override
  String get zoomOut => 'Perkecil';

  @override
  String get fitAllNodes => 'Muat semua node';

  @override
  String get hintBanner =>
      'Seret ke node untuk melampirkan · Naikkan: ⇈ · Ketuk dua kali: edit';

  @override
  String get hintBannerCompact =>
      'Seret ke node untuk melampirkan\nNaikkan: ⇈ · Ketuk dua kali: edit';

  @override
  String get themeVivid => 'Cerah';

  @override
  String get themePastel => 'Pastel';

  @override
  String get themeEarth => 'Earth';

  @override
  String get hue => 'Hue';

  @override
  String get sat => 'Jenuh';

  @override
  String get bright => 'Terang';

  @override
  String get layoutSection => 'Tata letak';

  @override
  String get starterSection => 'Kerangka';

  @override
  String get starterBlank => 'Kosong';

  @override
  String get starterPrd => 'PRD';

  @override
  String get starterEntities => 'Entitas';

  @override
  String get starterBlankDesc => 'Satu node pusat. Bangun dari awal.';

  @override
  String get starterPrdDesc =>
      'Kerangka kebutuhan produk: masalah, tujuan, pengguna, ruang lingkup.';

  @override
  String get starterEntitiesDesc =>
      'Contoh entitas beserta atribut — sketsa tabel yang saling terkait.';

  @override
  String get prdProblem => 'Masalah / peluang';

  @override
  String get prdGoals => 'Tujuan';

  @override
  String get prdGoalExample => 'Tujuan 1';

  @override
  String get prdUsers => 'Pengguna & persona';

  @override
  String get prdPersona => 'Persona';

  @override
  String get prdRequirements => 'Kebutuhan';

  @override
  String get prdMustHave => 'Wajib ada';

  @override
  String get prdNiceToHave => 'Bagus jika ada';

  @override
  String get prdScope => 'Ruang lingkup';

  @override
  String get prdInScope => 'Termasuk';

  @override
  String get prdOutOfScope => 'Tidak termasuk';

  @override
  String get prdMetrics => 'Metrik keberhasilan';

  @override
  String get prdQuestions => 'Pertanyaan terbuka';

  @override
  String get entityUser => 'User';

  @override
  String get entityAccount => 'Account';

  @override
  String get entityOrder => 'Order';

  @override
  String get entityProduct => 'Product';

  @override
  String get attrId => 'id';

  @override
  String get attrName => 'name';

  @override
  String get attrEmail => 'email';

  @override
  String get attrUserId => 'userId';

  @override
  String get attrAccountId => 'accountId';

  @override
  String get attrStatus => 'status';

  @override
  String get attrTotal => 'total';

  @override
  String get attrSku => 'sku';

  @override
  String get attrPrice => 'price';

  @override
  String get howToUse => 'Cara memakai';

  @override
  String get helpIntro =>
      'Mindmap adalah Peta Pikiran anda. SimplyMind adalah mindmap yang simple dan offline. Mindmap tersimpan di device sebagai JSON. Panduan ini mencakup daftar beranda, editor kanvas, kerangka, ekspor, dan instalasi.';

  @override
  String get helpHomeTitle => 'Beranda: mindmap Anda';

  @override
  String get helpHomeBody =>
      'Layar beranda menampilkan semua mindmap di perangkat ini, yang terbaru di atas. Ketuk mindmap untuk membuka editor. Menu ⋮ pada baris untuk mengubah nama, duplikat, pindah kategori, ekspor JSON, atau hapus.\n\nTombol + Mindmap baru memulai judul, kerangka, dan tata letak. Impor JSON dari ikon folder di bilah atas.';

  @override
  String get helpCreateTitle => 'Buat: kerangka dan tata letak';

  @override
  String get helpCreateBody =>
      'Kerangka adalah isi awal. Kosong = satu node pusat. PRD = kerangka produk (masalah, tujuan, pengguna, kebutuhan, ruang lingkup). Entitas = sketsa tabel terkait (User, Account, Order, Product) dengan field sebagai anak — bukan diagram database lengkap.\n\nTata letak mengatur posisi node: Mindmap (seret bebas), Daftar (garis besar), Langkah (alur bernomor), Grafik (mengelilingi induk). Tata letak bisa diubah nanti di editor. PRD menyarankan Daftar; Entitas menyarankan Grafik.';

  @override
  String get helpEditTitle => 'Editor: node dan cabang';

  @override
  String get helpEditBody =>
      'Ketuk node untuk memilih dan menampilkan toolbar. Ketuk dua kali untuk mengedit teks. + menambah anak (di mode Mindmap, mencari ruang kosong dekat saudara). Seret node non-akar ke node lain untuk mengganti induk. Naikkan (⇈) membuat node menjadi saudara dari induknya.\n\nDi Daftar/Langkah/Grafik, gunakan tombol panah untuk mengurutkan saudara. Template cabang mengubah tata letak subtree itu. Status (tanpa / sedang dikerjakan / selesai) dan warna ada di tiap node. Pengaturan mindmap (ikon tune) mengubah padding antara teks dan kotak.';

  @override
  String get helpCanvasTitle => 'Kanvas: zoom dan fokus';

  @override
  String get helpCanvasBody =>
      'Cubit atau gunakan + / − untuk zoom. Muat semua menampilkan setiap node di layar (juga saat mindmap pertama dibuka). Mode fokus (ikon layar penuh) menyembunyikan bilah atas dan overlay agar kanvas lebih luas. Petunjuk di bawah merangkum seret, naikkan, dan ketuk dua kali.';

  @override
  String get helpOrganizeTitle => 'Kategori';

  @override
  String get helpOrganizeBody =>
      'Mindmap mulai di Beranda. Setelah banyak mindmap, SimplyMind menawarkan kategori. Buat dari Lainnya atau baris chip. Saring dengan Semua / Beranda / nama Anda. Pindahkan mindmap dari menu ⋮. Menghapus kategori mengembalikan mindmap ke Beranda; mindmap-nya tidak dihapus.';

  @override
  String get helpExportTitle => 'Ekspor, impor, dan bagikan';

  @override
  String get helpExportBody =>
      'Di editor, menu bagikan mengekspor JSON (cadangan yang bisa diedit), PNG (gambar seluruh mindmap), atau PDF. Impor JSON ada di beranda. PNG/PDF menggambar ulang seluruh pohon — bukan tangkapan layar zoom saat ini.';

  @override
  String get helpOfflineTitle => 'Web, instal, dan luring';

  @override
  String get helpOfflineBody =>
      'Di situs web Anda bisa Tambahkan ke Layar Utama. Setelah sekali kunjungan online, aplikasi bisa dibuka tanpa internet (service worker). Mindmap tetap di penyimpanan lokal. Buka situs dengan HTTPS. iOS bisa menghapus data situs yang lama tidak dibuka — ekspor JSON sebagai cadangan. Build Android/iOS native menyimpan data di perangkat tanpa batas web itu.';

  @override
  String get helpLanguageTitle => 'Bahasa';

  @override
  String get helpLanguageBody =>
      'Lainnya → Bahasa: ikuti perangkat, English, atau Bahasa Indonesia. Menu dan panduan ini berubah; teks yang Anda ketik di node tidak.';

  @override
  String get helpFeedbackTitle => 'Masukan dan legal';

  @override
  String get helpFeedbackBody =>
      'Lainnya → Kirim masukan membuka WhatsApp dengan pesan singkat. Kebijakan Privasi dan DMCA ada di menu yang sama.';

  @override
  String get relations => 'Relasi';

  @override
  String get manageRelations => 'Kelola relasi';

  @override
  String get addRelation => 'Tambah relasi';

  @override
  String get editRelation => 'Edit relasi';

  @override
  String get removeRelation => 'Hapus relasi';

  @override
  String get relationTarget => 'Hubungkan ke node';

  @override
  String get relationLabel => 'Label relasi';

  @override
  String get relationLabelHint => 'mis. milik';

  @override
  String get relationCardinality => 'Kardinalitas';

  @override
  String get relationCardinalityHint => 'mis. N:1';

  @override
  String get noRelations => 'Belum ada relasi tambahan.';

  @override
  String get noRelationTargets => 'Semua node lain sudah terhubung.';

  @override
  String get relationBelongsTo => 'milik';

  @override
  String get relationContains => 'berisi';

  @override
  String get helpRelationsTitle => 'Relasi tambahan';

  @override
  String get helpRelationsBody =>
      'Satu node memiliki satu induk untuk tata letak, tetapi dapat memiliki banyak relasi tambahan. Pilih node → Relasi, pilih node lain, lalu tambahkan label dan kardinalitas opsional (misalnya milik, N:1). Relasi memakai panah putus-putus melengkung yang menempel ke tepi kotak dan tidak mengubah tata letak pohon. Relasi yang sama dengan cabang induk-anak tidak digambar dua kali.';
}
