const columnQueryString = 'queryString';
const columnUserHistory = 'userHistory';
const columnRankingOfBookmarks = 'rankingOfBookmarks';
const columnTime = 'time';

class SearchLog {
  String queryString;
  String userHistory;
  List<int> rankingOfBookmarks;

  // List<String> candidateProducts = [];
  DateTime time;

  SearchLog(
      {required this.queryString,
      required this.userHistory,
      required this.rankingOfBookmarks,
      required this.time});

  Map<String, dynamic> toMap() {
    return {
      columnQueryString: queryString,
      columnUserHistory: userHistory,
      columnRankingOfBookmarks: rankingOfBookmarks.join(' ,'),
      columnTime: time
    };
  }
}
