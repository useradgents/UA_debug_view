/// ua_debug_view — A modular, customizable Flutter debug panel by UserAdgents.
library;

// Core entry point
export 'src/presentation/debug_panel.dart';

// Triggers
export 'src/presentation/triggers/debug_trigger.dart';

// Module contract
export 'src/domain/module/debug_module.dart';

// Entities (public API)
export 'src/domain/entities/debug_environment.dart';
export 'src/domain/entities/debug_log.dart';
export 'src/domain/entities/debug_network_request.dart';
export 'src/domain/entities/debug_storage_provider.dart';
export 'src/domain/entities/debug_action.dart';
export 'src/domain/entities/debug_toggle_action.dart';
export 'src/domain/entities/test_account.dart';

// Built-in modules
export 'src/presentation/modules/app_info/app_info_module.dart';
export 'src/presentation/modules/environment/environment_module.dart';
export 'src/presentation/modules/auth/auth_module.dart';
export 'src/presentation/modules/test_accounts/test_accounts_module.dart';
export 'src/presentation/modules/network/network_module.dart';
export 'src/presentation/modules/logs/logs_module.dart';
export 'src/presentation/modules/storage/storage_module.dart';
export 'src/presentation/modules/actions/actions_module.dart';
export 'src/presentation/modules/design_system/design_system_module.dart';
export 'src/presentation/modules/custom/custom_module.dart';

// Data utilities
export 'src/data/logger/debug_logger.dart';
export 'src/data/network/debug_http_client.dart';
export 'src/data/network/debug_network_store.dart';
