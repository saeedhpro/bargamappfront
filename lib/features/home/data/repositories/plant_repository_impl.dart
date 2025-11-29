import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/plant.dart';
import '../../domain/repositories/plant_repository.dart';
import '../datasources/plant_remote_data_source.dart';
import '../datasources/plant_local_data_source.dart';

class PlantRepositoryImpl implements PlantRepository {
  final PlantRemoteDataSource remoteDataSource;
  final PlantLocalDataSource localDataSource;

  PlantRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Plant>>> getPlants() async {
    try {
      final plants = await remoteDataSource.getAllPlants();
      await localDataSource.cachePlants(plants);
      return Right(plants.cast<Plant>());
    } on ServerException catch (e) {
      try {
        final cachedPlants = await localDataSource.getCachedPlants();
        return Right(cachedPlants.cast<Plant>());
      } on CacheException {
        return Left(ServerFailure(e.message));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Plant>>> searchPlants(String query) async {
    try {
      final plants = await remoteDataSource.searchPlants(query);
      return Right(plants.cast<Plant>());
    } on ServerException catch (e) {
      try {
        final cachedPlants = await localDataSource.getCachedPlants();
        final filtered = cachedPlants.where((plant) {
          return plant.commonName.toString().toLowerCase().contains(query.toLowerCase()) ||
              plant.plantName.toLowerCase().contains(query.toLowerCase());
        }).toList();
        return Right(filtered.cast<Plant>());
      } on CacheException {
        return Left(ServerFailure(e.message));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Plant>> getPlantById(String id) async {
    try {
      final plant = await remoteDataSource.getPlantById(id);
      return Right(plant as Plant);
    } on ServerException catch (e) {
      try {
        final cachedPlants = await localDataSource.getCachedPlants();
        final plant = cachedPlants.firstWhere((p) => p.id == id);
        return Right(plant as Plant);
      } on CacheException {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('گیاه یافت نشد'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Plant>>> getHistoryPlants({int page = 1, String? search}) async {
    try {
      final remotePlants = await remoteDataSource.getHistoryPlants(page: page, search: search);

      final plants = remotePlants.map((model) => model.toEntity()).toList();

      return Right(plants.cast<Plant>());
    } on ServerException {
      return const Left(ServerFailure());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}
