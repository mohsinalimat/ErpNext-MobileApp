import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/datasources/quotation_remote_datasource.dart';
import '../../data/repositories/quotation_repository_impl.dart';
import '../../domain/usecases/add_quotation_follow_up_usecase.dart';
import '../../domain/usecases/execute_quotation_workflow_action_usecase.dart';
import '../../domain/usecases/get_quotations_dashboard_summary_usecase.dart';
import '../../domain/usecases/get_quotations_usecase.dart';
import '../../domain/usecases/get_quotation_details_usecase.dart';
import '../../domain/usecases/get_quotation_print_data_usecase.dart';
import '../../domain/usecases/get_quotation_workflow_actions_usecase.dart';
import '../../domain/usecases/upload_quotation_attachment_usecase.dart';
import '../providers/quotations_provider.dart';
import '../providers/quotation_details_provider.dart';

class QuotationScope extends StatelessWidget {
  final Widget child;

  const QuotationScope({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = QuotationRemoteDataSource();
    final repository = QuotationRepositoryImpl(remoteDataSource);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => QuotationsProvider(
            GetQuotationsUseCase(repository),
            GetQuotationsDashboardSummaryUseCase(repository),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => QuotationDetailsProvider(
            GetQuotationDetailsUseCase(repository),
            AddQuotationFollowUpUseCase(repository),
            GetQuotationWorkflowActionsUseCase(repository),
            ExecuteQuotationWorkflowActionUseCase(repository),
            UploadQuotationAttachmentUseCase(repository),
            GetQuotationPrintDataUseCase(repository),
          ),
        ),
      ],
      child: child,
    );
  }
}
