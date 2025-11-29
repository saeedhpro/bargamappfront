import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tool.dart';
import '../repositories/tool_repository.dart';

class GetAllTools {
  final ToolRepository repository;

  GetAllTools(this.repository);

  Future<Either<Failure, List<Tool>>> call() async {
    return await repository.getAllTools();
  }
}
