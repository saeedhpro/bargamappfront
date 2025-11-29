
import 'package:bargam_app/features/tools/data/models/tool_model.dart';

abstract class ToolRemoteDataSource {
  Future<List<ToolModel>> getAllTools();
  Future<List<ToolModel>> searchTools(String query);

  Future<dynamic> getTools() async {}

  Future<dynamic> getToolById(String id) async {}
}

class ToolRemoteDataSourceImpl implements ToolRemoteDataSource {
  @override
  Future<List<ToolModel>> getAllTools() async {
    return ToolModel.getStaticTools();
  }

  @override
  Future<List<ToolModel>> searchTools(String query) async {
    final allTools = ToolModel.getStaticTools();
    return allTools
        .where((tool) =>
    tool.title.contains(query) || tool.description.contains(query))
        .toList();
  }

  @override
  Future<dynamic> getTools() {
    // TODO: implement getTools
    throw UnimplementedError();
  }

  @override
  Future<dynamic> getToolById(String id) {
    // TODO: implement getToolById
    throw UnimplementedError();
  }
}
