import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Auth
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/navigation/presentation/pages/main_shell_page.dart';

// Projects
import 'features/projects/presentation/providers/projects_provider.dart';
import 'features/projects/presentation/providers/project_details_provider.dart';
import 'features/projects/data/datasources/project_remote_datasource.dart';
import 'features/projects/data/repositories/project_repository_impl.dart';
import 'features/projects/domain/usecases/get_projects_usecase.dart';
import 'features/projects/domain/usecases/get_project_details_usecase.dart';
import 'features/sales/lead/data/datasources/lead_remote_datasource.dart';
import 'features/sales/lead/data/repositories/lead_repository_impl.dart';
import 'features/sales/lead/domain/usecases/add_lead_follow_up_usecase.dart';
import 'features/sales/lead/domain/usecases/create_lead_usecase.dart';
import 'features/sales/lead/domain/usecases/get_lead_details_usecase.dart';
import 'features/sales/lead/domain/usecases/get_lead_required_fields_usecase.dart';
import 'features/sales/lead/domain/usecases/get_leads_usecase.dart';
import 'features/sales/lead/domain/usecases/get_leads_dashboard_summary_usecase.dart';
import 'features/sales/lead/domain/usecases/search_lead_link_options_usecase.dart';
import 'features/sales/lead/domain/usecases/upload_lead_attachment_usecase.dart';
import 'features/sales/lead/domain/usecases/update_lead_usecase.dart';
import 'features/sales/lead/presentation/providers/lead_details_provider.dart';
import 'features/sales/lead/presentation/providers/lead_form_provider.dart';
import 'features/sales/lead/presentation/providers/leads_provider.dart';

void main() {
  final authRepo = AuthRepositoryImpl();
  final loginUseCase = LoginUseCase(authRepo);

  final remoteDataSource = ProjectRemoteDataSource();
  final projectsRepo = ProjectRepositoryImpl(remoteDataSource);
  final getProjectsUseCase = GetProjectsUseCase(projectsRepo);
  final getProjectDetailsUseCase = GetProjectDetailsUseCase(projectsRepo);

  final leadRemoteDataSource = LeadRemoteDataSource();
  final leadsRepo = LeadRepositoryImpl(leadRemoteDataSource);
  final getLeadsUseCase = GetLeadsUseCase(leadsRepo);
  final getLeadsDashboardSummaryUseCase = GetLeadsDashboardSummaryUseCase(
    leadsRepo,
  );
  final getLeadDetailsUseCase = GetLeadDetailsUseCase(leadsRepo);
  final getLeadRequiredFieldsUseCase = GetLeadRequiredFieldsUseCase(leadsRepo);
  final createLeadUseCase = CreateLeadUseCase(leadsRepo);
  final updateLeadUseCase = UpdateLeadUseCase(leadsRepo);
  final addLeadFollowUpUseCase = AddLeadFollowUpUseCase(leadsRepo);
  final searchLeadLinkOptionsUseCase = SearchLeadLinkOptionsUseCase(leadsRepo);
  final uploadLeadAttachmentUseCase = UploadLeadAttachmentUseCase(leadsRepo);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(loginUseCase)..restoreSession(),
        ),
        ChangeNotifierProvider(create: (_) => ProjectsProvider(getProjectsUseCase)),
        ChangeNotifierProvider(
          create: (_) => ProjectDetailsProvider(getProjectDetailsUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => LeadsProvider(
            getLeadsUseCase,
            getLeadsDashboardSummaryUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => LeadDetailsProvider(
            getLeadDetailsUseCase,
            addLeadFollowUpUseCase,
            uploadLeadAttachmentUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => LeadFormProvider(
            getLeadRequiredFieldsUseCase,
            createLeadUseCase,
            updateLeadUseCase,
            searchLeadLinkOptionsUseCase,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E7490),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'ERP Mobile App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F8FB),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isInitializing) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return auth.isAuthenticated ? const MainShellPage() : const LoginPage();
        },
      ),
    );
  }
}
