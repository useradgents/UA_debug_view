import 'package:flutter/material.dart';
import 'debug_environment.dart';

/// A test account usable in [TestAccountsModule].
class TestAccount {
  /// Human-readable label shown in the list.
  final String label;

  /// Optional description shown below the label.
  final String? description;

  /// Custom style for [description]. Defaults to white 12sp if not provided.
  final TextStyle? descriptionStyle;

  /// Arbitrary credential map (e.g. `{'email': '...', 'password': '...'}`).
  final Map<String, String> credentials;

  /// If non-empty, the account only appears when the active environment
  /// matches one of these entries. Pass empty list to always show.
  final List<DebugEnvironment> environments;

  /// Optional tags displayed as chips (e.g. 'bronze', 'loyalty').
  final List<String> tags;

  const TestAccount({
    required this.label,
    this.description,
    this.descriptionStyle,
    required this.credentials,
    this.environments = const [],
    this.tags = const [],
  });

  /// Convenience constructor for the common email/password pattern.
  factory TestAccount.emailPassword({
    required String label,
    required String email,
    required String password,
    String? description,
    TextStyle? descriptionStyle,
    List<DebugEnvironment> environments = const [],
    List<String> tags = const [],
  }) {
    return TestAccount(
      label: label,
      description: description,
      descriptionStyle: descriptionStyle,
      credentials: {'email': email, 'password': password},
      environments: environments,
      tags: tags,
    );
  }

  /// Convenience constructor for the common phone/password pattern.
  factory TestAccount.phonePassword({
    required String label,
    required String phone,
    required String password,
    String? description,
    TextStyle? descriptionStyle,
    List<DebugEnvironment> environments = const [],
    List<String> tags = const [],
  }) {
    return TestAccount(
      label: label,
      description: description,
      descriptionStyle: descriptionStyle,
      credentials: {'phone': phone, 'password': password},
      environments: environments,
      tags: tags,
    );
  }
}
