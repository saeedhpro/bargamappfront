import 'package:bargam_app/features/tools/domain/entities/tool.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class ToolRepository {
  Future<Either<Failure, List<Tool>>> getAllTools();
  Future<Either<Failure, List<Tool>>> searchTools(String query);
}
