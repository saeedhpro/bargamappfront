import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/plant.dart';
import '../../domain/repositories/plant_repository.dart';

class GetHistoryPlants {
  final PlantRepository repository;

  GetHistoryPlants(this.repository);

  Future<Either<Failure, List<Plant>>> call({int page = 1, String? search}) async {
    return await repository.getHistoryPlants(page: page, search: search);
  }
}
