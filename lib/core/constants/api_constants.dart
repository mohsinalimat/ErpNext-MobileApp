class ApiConstants {
  static const String baseUrl = "http://192.168.100.107:8000";

  static const String loginEndpoint = "/api/method/mobile_api.api.login";
  static const String sessionLoginEndpoint = "/api/method/login";
  static const String projectsEndpoint =
      "/api/method/mobile_api.api.get_my_projects";
  static const String projectDetailsEndpoint =
      "/api/method/mobile_api.api.get_project_details";
  static const String taskDetailsEndpoint =
      "/api/method/mobile_api.api.get_task_details";
  static const String addFollowUpEndpoint =
      "/api/method/mobile_api.api.add_follow_up";
  static const String leadsEndpoint =
      "/api/method/mobile_api.api.get_leads";
  static const String leadDetailsEndpoint =
      "/api/method/mobile_api.api.get_lead_details";
  static const String leadRequiredFieldsEndpoint =
      "/api/method/mobile_api.api.get_lead_required_fields";
  static const String createLeadEndpoint =
      "/api/method/mobile_api.api.create_lead";
  static const String updateLeadEndpoint =
      "/api/method/mobile_api.api.update_lead";
  static const String addLeadFollowUpEndpoint =
      "/api/method/mobile_api.api.add_lead_follow_up";
  static const String leadFollowUpsEndpoint =
      "/api/method/mobile_api.api.get_lead_follow_ups";
  static const String leadsDashboardSummaryEndpoint =
      "/api/method/mobile_api.api.get_leads_dashboard_summary";
  static const String searchLinkEndpoint =
      "/api/method/frappe.desk.search.search_link";

  static Uri uri(String endpoint) => Uri.parse("$baseUrl$endpoint");
}
