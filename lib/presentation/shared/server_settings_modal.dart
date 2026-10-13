import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';
import '../family_portal/resident_provider.dart';

class ServerSettingsModal extends ConsumerStatefulWidget {
  /// Optional override callback for connection testing (useful in widget tests).
  final Future<ConnectionTestResult> Function(String candidateUrl)?
      onTestConnection;

  const ServerSettingsModal({
    super.key,
    this.onTestConnection,
  });

  static Future<void> show(
    BuildContext context, {
    Future<ConnectionTestResult> Function(String candidateUrl)?
        onTestConnection,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ServerSettingsModal(onTestConnection: onTestConnection),
    );
  }

  @override
  ConsumerState<ServerSettingsModal> createState() =>
      _ServerSettingsModalState();
}

class _ServerSettingsModalState extends ConsumerState<ServerSettingsModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  bool _isTesting = false;
  ConnectionTestResult? _testResult;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final currentConfig = ref.read(appConfigProvider);
    _urlController = TextEditingController(text: currentConfig.apiBaseUrl);
    _urlController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (_validationError != null || _testResult != null) {
      setState(() {
        _validationError = null;
        _testResult = null;
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_onInputChanged);
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleTestConnection() async {
    final input = _urlController.text.trim();
    final error = AppConfig.validateBaseUrl(input);
    if (error != null) {
      setState(() {
        _validationError = error;
        _testResult = null;
      });
      return;
    }

    setState(() {
      _validationError = null;
      _isTesting = true;
      _testResult = null;
    });

    final tester = widget.onTestConnection;
    final result = tester != null
        ? await tester(input)
        : await ref.read(apiClientProvider).testConnection(input);

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _testResult = result;
    });
  }

  Future<void> _handleSave() async {
    final input = _urlController.text.trim();
    final error = AppConfig.validateBaseUrl(input);
    if (error != null) {
      setState(() {
        _validationError = error;
      });
      return;
    }

    final normalized = AppConfig.normalizeBaseUrl(input);
    await ref.read(appConfigProvider.notifier).setCustomBaseUrl(normalized);
    ref.invalidate(demoAccountsProvider);
    final currentUser = ref.read(authProvider).user;
    if (currentUser != null) {
      await ref.read(authProvider.notifier).selectDemoProfile(currentUser.username);
    }
    await ref.read(residentProvider.notifier).refreshCurrentResident();

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Server base URL updated to $normalized'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _handleReset() async {
    await ref.read(appConfigProvider.notifier).resetBaseUrl();
    final updatedConfig = ref.read(appConfigProvider);
    _urlController.text = updatedConfig.apiBaseUrl;
    ref.invalidate(demoAccountsProvider);
    final currentUser = ref.read(authProvider).user;
    if (currentUser != null) {
      await ref.read(authProvider.notifier).selectDemoProfile(currentUser.username);
    }
    await ref.read(residentProvider.notifier).refreshCurrentResident();

    if (!mounted) return;
    setState(() {
      _validationError = null;
      _testResult = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Server base URL reset to default (${updatedConfig.apiBaseUrl})'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final rawInput = _urlController.text.trim();
    final isValidPreview = AppConfig.validateBaseUrl(rawInput) == null;
    final normalizedPreview =
        isValidPreview ? AppConfig.normalizeBaseUrl(rawInput) : null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.dns_outlined,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Server Connection Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Point the mobile app to your MacBook or local Wi-Fi microservices stack.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Base URL',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: config.isCustomUrlActive
                                  ? AppColors.primaryLight
                                  : AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              config.isCustomUrlActive
                                  ? 'Custom Override'
                                  : 'Default',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: config.isCustomUrlActive
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        config.apiBaseUrl,
                        key: const Key('active_base_url_text'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Microservices Base URL or Host IP',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('server_url_input'),
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText:
                        'e.g. 192.168.1.50 or http://192.168.1.50:8080/api/v1',
                    prefixIcon: const Icon(Icons.link),
                    errorText: _validationError,
                    suffixIcon: _urlController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            tooltip: 'Clear input',
                            onPressed: () => _urlController.clear(),
                          )
                        : null,
                  ),
                ),
                if (normalizedPreview != null &&
                    normalizedPreview != rawInput) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Normalized URL: $normalizedPreview',
                    key: const Key('normalized_url_preview'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (_testResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    key: const Key('connection_test_banner'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _testResult!.isSuccess
                          ? AppColors.surfaceVariant
                          : AppColors.allergyRedBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _testResult!.isSuccess
                            ? AppColors.primary.withAlpha(80)
                            : AppColors.allergyRed.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _testResult!.isSuccess
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          color: _testResult!.isSuccess
                              ? AppColors.primary
                              : AppColors.allergyRed,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _testResult!.message,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _testResult!.isSuccess
                                  ? AppColors.textPrimary
                                  : AppColors.allergyRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('test_connection_button'),
                        onPressed: _isTesting ? null : _handleTestConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_find, size: 18),
                        label: Text(
                            _isTesting ? 'Testing...' : 'Test Connection'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('reset_base_url_button'),
                        onPressed: _handleReset,
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: const Text('Reset to Default'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  key: const Key('save_base_url_button'),
                  onPressed: _handleSave,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Save & Apply'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
