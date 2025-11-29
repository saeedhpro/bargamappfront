import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/plant.dart';

abstract class PlantRepository {
  Future<Either<Failure, List<Plant>>> getPlants();
  Future<Either<Failure, Plant>> getPlantById(String id);
  Future<Either<Failure, List<Plant>>> searchPlants(String query);
  Future<Either<Failure, List<Plant>>> getHistoryPlants({int page = 1, String? search});
}
