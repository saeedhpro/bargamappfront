import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tool.dart';

abstract class ToolRepository {
  Future<Either<Failure, List<Tool>>> getAllTools();
  Future<Either<Failure, List<Tool>>> searchTools(String query);
  Future<Either<Failure, Tool>> getToolById(String id);
}
