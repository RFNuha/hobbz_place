// @HiveType(typeId: 3)
enum Genre {
  // @HiveField(0)
  action,

  // @HiveField(1)
  adventure,

  // @HiveField(2)
  comedy,

  // @HiveField(3)
  drama,

  // @HiveField(4)
  fantasy,

  // @HiveField(5)
  horror,

  // @HiveField(6)
  mystery,

  // @HiveField(7)
  romance,

  // @HiveField(8)
  sciFi,

  // @HiveField(9)
  sliceOfLife,

  // @HiveField(10)
  thriller,

  // @HiveField(11)
  historical,

  // @HiveField(12)
  isekai,           

  // @HiveField(13)
  martialArts,      

  // @HiveField(14)
  psychological,

  // @HiveField(15)
  sports,

  // @HiveField(16)
  music,

  // @HiveField(17)
  documentary,

  // @HiveField(18)
  crime,
}

extension GenreExtension on Genre {

     String get displayName {
    switch (this) {
      case Genre.action:        return 'Action';
      case Genre.adventure:     return 'Adventure';
      case Genre.comedy:        return 'Comedy';
      case Genre.drama:         return 'Drama';
      case Genre.fantasy:       return 'Fantasy';
      case Genre.horror:        return 'Horror';
      case Genre.mystery:       return 'Mystery';
      case Genre.romance:       return 'Romance';
      case Genre.sciFi:         return 'Sci-Fi';
      case Genre.sliceOfLife:   return 'Slice of Life';
      case Genre.thriller:      return 'Thriller';
      case Genre.historical:    return 'Historical';
      case Genre.isekai:        return 'Isekai';
      case Genre.martialArts:   return 'Martial Arts';
      case Genre.psychological: return 'Psychological';
      case Genre.sports:        return 'Sports';
      case Genre.music:         return 'Music';
      case Genre.documentary:   return 'Documentary';
      case Genre.crime:         return 'Crime';
    }
  }
}