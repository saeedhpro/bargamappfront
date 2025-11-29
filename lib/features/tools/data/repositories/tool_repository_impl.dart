import 'package:bargam_app/features/home/data/datasources/tool_local_data_source.dart';
import 'package:bargam_app/features/home/data/datasources/tool_remote_data_source.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/tool.dart';
import '../../domain/repositories/tool_repository.dart';

class ToolRepositoryImpl implements ToolRepository {
  final ToolRemoteDataSource remoteDataSource;
  final ToolLocalDataSource localDataSource;

  ToolRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  Future<Either<Failure, List<Tool>>> getTools() async {
    try {
      // ابتدا سعی می‌کنیم از منبع ریموت بگیریم (که استاتیک است)
      final tools = await remoteDataSource.getTools();

      // ذخیره در کش
      await localDataSource.cacheTools(tools);

      return Right(tools);
    } on ServerException catch (e) {
      // اگر خطای سرور بود، از کش استفاده کنیم
      try {
        final cachedTools = await localDataSource.getCachedTools();
        return Right(cachedTools);
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
  Future<Either<Failure, List<Tool>>> searchTools(String query) async {
    try {
      // جستجو در ابزارهای استاتیک
      final tools = await remoteDataSource.searchTools(query);
      return Right(tools);
    } on ServerException catch (e) {
      // اگر خطا بود، در کش جستجو کنیم
      try {
        final cachedTools = await localDataSource.getCachedTools();
        final filtered = cachedTools.where((tool) {
          return tool.title.toLowerCase().contains(query.toLowerCase()) ||
              tool.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
        return Right(filtered);
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
  Future<Either<Failure, Tool>> getToolById(String id) async {
    try {
      final tool = await remoteDataSource.getToolById(id);
      return Right(tool);
    } on ServerException catch (e) {
      // جستجو در کش
      try {
        final cachedTools = await localDataSource.getCachedTools();
        final tool = cachedTools.firstWhere((t) => t.id == id);
        return Right(tool);
      } on CacheException {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('ابزار یافت نشد'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطای غیرمنتظره: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Tool>>> getAllTools() {
    // TODO: implement getAllTools
    throw UnimplementedError();
  }
}
