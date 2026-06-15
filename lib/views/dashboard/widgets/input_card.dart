import 'package:flutter/material.dart';

class InputCard extends StatefulWidget {
  final Future<void> Function(String name) onAddName;

  const InputCard({
    super.key,
    required this.onAddName,
  });

  @override
  State<InputCard> createState() => _InputCardState();
}

class _InputCardState extends State<InputCard> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final name = _nameController.text.trim();

    try {
      await widget.onAddName(name);
      _nameController.clear();
    } catch (_) {
      // Errors should be handled by the parent widget / showSnackBar
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter User Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Lakshyajeet Singh',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submitData(),
                  ),
                ),
                const SizedBox(width: 16),
                _isSubmitting
                    ? Container(
                        height: 52,
                        width: 100,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      )
                    : Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _submitData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.send_rounded, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'SUBMIT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
