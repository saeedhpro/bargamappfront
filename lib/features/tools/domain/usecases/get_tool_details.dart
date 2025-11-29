import 'package:bargam_app/features/tools/domain/repositories/tool_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tool.dart';

class GetToolDetails {
  final ToolRepository repository;

  GetToolDetails(this.repository);

  Future<Either<Failure, Tool>> call(String id) async {
    return await repository.getToolById(id);
  }
}
