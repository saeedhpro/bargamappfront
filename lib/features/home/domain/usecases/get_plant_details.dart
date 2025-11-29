import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/plant.dart';
import '../repositories/plant_repository.dart';

class GetPlantDetails {
  final PlantRepository repository;

  GetPlantDetails(this.repository);

  Future<Either<Failure, Plant>> call(String plantId) async {
    return await repository.getPlantById(plantId);
  }
}
