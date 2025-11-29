import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/plant.dart';
import '../repositories/plant_repository.dart';

class SearchPlants {
  final PlantRepository repository;

  SearchPlants(this.repository);

  Future<Either<Failure, List<Plant>>> call(String query) async {
    return await repository.searchPlants(query);
  }
}
