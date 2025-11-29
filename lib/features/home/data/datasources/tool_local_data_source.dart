import 'package:bargam_app/features/tools/data/models/tool_model.dart';

abstract class ToolLocalDataSource {
  Future<List<ToolModel>> getCachedTools();
  Future<void> cacheTools(List<ToolModel> tools);
}

class ToolLocalDataSourceImpl implements ToolLocalDataSource {
  @override
  Future<List<ToolModel>> getCachedTools() async {
    return ToolModel.getStaticTools();
  }

  @override
  Future<void> cacheTools(List<ToolModel> tools) async {
  }
}
