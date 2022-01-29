import 'product.dart';

const columnQueryString = 'queryString';
const columnUserHistory = 'userHistory';
const columnRankingOfBookmarks = 'rankingOfBookmarks';
const columnTime = 'time';
const columnResults = "results";

class SearchLog {
  String queryString;
  String userHistory;
  List<int> rankingOfBookmarks;
  List<Product> results;

  // List<String> candidateProducts = [];
  DateTime time;

  SearchLog(
      {required this.queryString,
      required this.userHistory,
      required this.rankingOfBookmarks,
        required this.results,
      required this.time});

  Map<String, dynamic> toMap() {
    return {
      columnQueryString: queryString,
      columnUserHistory: userHistory,
      columnRankingOfBookmarks: rankingOfBookmarks.join(', '),
      columnResults: results.map((p) => p.name).join(', '),
      columnTime: time
    };
  }
}
