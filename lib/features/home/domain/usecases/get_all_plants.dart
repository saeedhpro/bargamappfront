import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/plant.dart';
import '../repositories/plant_repository.dart';

class GetAllPlants {
  final PlantRepository repository;

  GetAllPlants(this.repository);

  Future<Either<Failure, List<Plant>>> call() async {
    return await repository.getPlants();
  }
}
