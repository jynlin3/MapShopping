import 'product.dart';

const columnQueryString = 'queryString';
const columnUserHistory = 'userHistory';
const columnRankingOfBookmarks = 'rankingOfBookmarks';
const columnTime = 'time';
const columnResults = "results";
const columnWeek = "week";

class SearchLog {
  String queryString;
  String userHistory;
  List<int> rankingOfBookmarks;
  List<Product> results;
  int week;

  // List<String> candidateProducts = [];
  DateTime time;

  SearchLog(
      {required this.queryString,
      required this.userHistory,
      required this.rankingOfBookmarks,
      required this.results,
      required this.time,
      required this.week});

  Map<String, dynamic> toMap() {
    return {
      columnQueryString: queryString,
      columnUserHistory: userHistory,
      columnRankingOfBookmarks: rankingOfBookmarks,
      columnResults: results.map((p) => p.name).toList(),
      columnTime: time,
      columnWeek: week
    };
  }
}
