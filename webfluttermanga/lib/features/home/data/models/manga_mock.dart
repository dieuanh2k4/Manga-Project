class Manga {
  final int id;
  final String title;
  final String authorName;
  final String thumbnail;
  final String latestChapter;
  final int views;

  Manga({
    required this.id,
    required this.title,
    required this.authorName,
    required this.thumbnail,
    required this.latestChapter,
    this.views = 0,
  });
}

// Dữ liệu giả lập cho UI theo backend
final List<Manga> mockMangaList = [
  Manga(
    id: 1,
    title: 'So you weren’t into me?!',
    authorName: 'Wakame Konbu',
    thumbnail: 'https://images.unsplash.com/photo-1541562232579-512a21360020?q=80&w=600',
    latestChapter: '#008',
    views: 273500,
  ),
  Manga(
    id: 2,
    title: 'WITCHRIV',
    authorName: 'Tatsuya Endo',
    thumbnail: 'https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?q=80&w=600',
    latestChapter: '#021',
    views: 108200,
  ),
  Manga(
    id: 3,
    title: 'We\'re J-Just Childhood Friends',
    authorName: 'Yuto Suzuki',
    thumbnail: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?q=80&w=600',
    latestChapter: '#021',
    views: 59100,
  ),
  Manga(
    id: 4,
    title: 'Stop! I\'m Falling For You',
    authorName: 'Takeru Hokazono',
    thumbnail: 'https://images.unsplash.com/photo-1513360371669-4adf3dd7dff8?q=80&w=600',
    latestChapter: '#045',
    views: 50100,
  ),
  Manga(
    id: 5,
    title: 'Shiba Inu Rooms',
    authorName: 'Osamu Nishi',
    thumbnail: 'https://images.unsplash.com/photo-1560942485-b2a11cc13456?q=80&w=600',
    latestChapter: '#048',
    views: 20100,
  ),
  Manga(
    id: 6,
    title: 'Naruto Special',
    authorName: 'Masashi Kishimoto',
    thumbnail: 'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=600',
    latestChapter: '#700',
    views: 999900,
  ),
  Manga(
    id: 7,
    title: 'Enigmatica',
    authorName: 'Kohei Horikoshi',
    thumbnail: 'https://images.unsplash.com/photo-1493246507139-91e8fad9978e?q=80&w=600',
    latestChapter: '#105',
    views: 34500,
  ),
  Manga(
    id: 8,
    title: 'Kagurabachi',
    authorName: 'Takeru Hokazono',
    thumbnail: 'https://images.unsplash.com/photo-1618331835717-801e976710b2?q=80&w=600',
    latestChapter: '#032',
    views: 112800,
  ),
];

final List<Manga> mockHottestList = [
  Manga(
    id: 101,
    title: 'One Piece',
    authorName: 'Eiichiro Oda',
    thumbnail: 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?q=80&w=300',
    latestChapter: '#1111',
    views: 298703,
  ),
  Manga(
    id: 102,
    title: 'Boruto: Two Blue Vortex',
    authorName: 'Masashi Kishimoto / Mikio Ikemoto',
    thumbnail: 'https://images.unsplash.com/photo-1579546929662-711fa8127f5a?q=80&w=300',
    latestChapter: '#008',
    views: 231283,
  ),
  Manga(
    id: 103,
    title: 'Dandadan',
    authorName: 'Yukinobu Tatsu',
    thumbnail: 'https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=300',
    latestChapter: '#148',
    views: 173145,
  ),
  Manga(
    id: 104,
    title: 'SPY x FAMILY',
    authorName: 'Tatsuya Endo',
    thumbnail: 'https://images.unsplash.com/photo-1557682250-33bd709cbe85?q=80&w=300',
    latestChapter: '#097',
    views: 134442,
  ),
  Manga(
    id: 105,
    title: 'SAKAMOTO DAYS',
    authorName: 'Yuto Suzuki',
    thumbnail: 'https://images.unsplash.com/photo-1558655146-d09347e92766?q=80&w=300',
    latestChapter: '#161',
    views: 117887,
  ),
  Manga(
    id: 106,
    title: 'Kagurabachi',
    authorName: 'Takeru Hokazono',
    thumbnail: 'https://images.unsplash.com/photo-1557682224-5b8590cd9ec5?q=80&w=300',
    latestChapter: '#028',
    views: 112817,
  ),
  Manga(
    id: 107,
    title: 'Ichi the Witch',
    authorName: 'Osamu Nishi / Shiro Usazaki',
    thumbnail: 'https://images.unsplash.com/photo-1557683304-673a23048d34?q=80&w=300',
    latestChapter: '#012',
    views: 90388,
  )
];