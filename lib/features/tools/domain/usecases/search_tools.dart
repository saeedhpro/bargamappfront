import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tool.dart';
import '../repositories/tool_repository.dart';

class SearchTools {
  final ToolRepository repository;

  SearchTools(this.repository);

  Future<Either<Failure, List<Tool>>> call(String query) async {
    return await repository.searchTools(query);
  }
}
