import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/datasources/opportunity_remote_datasource.dart';
import '../../data/repositories/opportunity_repository_impl.dart';
import '../../domain/usecases/add_opportunity_follow_up_usecase.dart';
import '../../domain/usecases/create_opportunity_usecase.dart';
import '../../domain/usecases/execute_opportunity_workflow_action_usecase.dart';
import '../../domain/usecases/get_opportunities_dashboard_summary_usecase.dart';
import '../../domain/usecases/get_opportunities_usecase.dart';
import '../../domain/usecases/get_opportunity_details_usecase.dart';
import '../../domain/usecases/get_opportunity_form_usecase.dart';
import '../../domain/usecases/get_opportunity_party_prefill_usecase.dart';
import '../../domain/usecases/get_opportunity_required_fields_usecase.dart';
import '../../domain/usecases/get_opportunity_workflow_actions_usecase.dart';
import '../../domain/usecases/search_opportunity_link_options_usecase.dart';
import '../../domain/usecases/update_opportunity_usecase.dart';
import '../../domain/usecases/upload_opportunity_attachment_usecase.dart';
import '../providers/opportunities_provider.dart';
import '../providers/opportunity_details_provider.dart';
import '../providers/opportunity_form_provider.dart';

class OpportunityScope extends StatelessWidget {
  final Widget child;

  const OpportunityScope({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = OpportunityRemoteDataSource();
    final repository = OpportunityRepositoryImpl(remoteDataSource);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => OpportunitiesProvider(
            GetOpportunitiesUseCase(repository),
            GetOpportunitiesDashboardSummaryUseCase(repository),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OpportunityDetailsProvider(
            GetOpportunityDetailsUseCase(repository),
            AddOpportunityFollowUpUseCase(repository),
            GetOpportunityWorkflowActionsUseCase(repository),
            ExecuteOpportunityWorkflowActionUseCase(repository),
            UploadOpportunityAttachmentUseCase(repository),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OpportunityFormProvider(
            GetOpportunityFormUseCase(repository),
            GetOpportunityPartyPrefillUseCase(repository),
            GetOpportunityRequiredFieldsUseCase(repository),
            CreateOpportunityUseCase(repository),
            UpdateOpportunityUseCase(repository),
            SearchOpportunityLinkOptionsUseCase(repository),
          ),
        ),
      ],
      child: child,
    );
  }
}
