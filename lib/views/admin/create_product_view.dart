import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CreateProductView extends StatefulWidget {
  const CreateProductView({super.key});

  @override
  State<CreateProductView> createState() => _CreateProductViewState();
}

class _CreateProductViewState extends State<CreateProductView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _picker = ImagePicker();
  final _api = ApiService();
  final _images = <XFile>[];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;
    setState(() {
      for (final image in picked) {
        if (!_images.any((existing) => existing.path == image.path)) {
          _images.add(image);
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      AppTheme.snack('Images required', 'Add at least one product image.', error: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _api.createProduct(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        category: _categoryController.text.trim(),
        price: int.parse(_priceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        imagePaths: _images.map((image) => image.path).toList(),
      );
      if (!mounted) return;
      _formKey.currentState!.reset();
      _nameController.clear();
      _brandController.clear();
      _categoryController.clear();
      _priceController.clear();
      _stockController.clear();
      setState(() => _images.clear());
      AppTheme.snack('Product created', 'The product is now in your catalog.');
    } catch (error) {
      if (!mounted) return;
      AppTheme.snack(
        'Could not create product',
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _positiveInteger(String? value, String label) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) return '$label must be a valid number';
    return null;
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a product',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add your product details and images. The product description will be generated automatically.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 22),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 620;
                        final fields = [
                          TextFormField(
                            controller: _nameController,
                            decoration: _decoration(
                              'Product name',
                              Icons.inventory_2_outlined,
                            ),
                            validator: (value) =>
                                _required(value, 'Product name'),
                          ),
                          TextFormField(
                            controller: _brandController,
                            decoration: _decoration(
                              'Brand',
                              Icons.sell_outlined,
                            ),
                            validator: (value) => _required(value, 'Brand'),
                          ),
                          TextFormField(
                            controller: _categoryController,
                            decoration: _decoration(
                              'Category',
                              Icons.category_outlined,
                            ),
                            validator: (value) => _required(value, 'Category'),
                          ),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: _decoration(
                              'Price',
                              Icons.payments_outlined,
                            ),
                            validator: (value) =>
                                _positiveInteger(value, 'Price'),
                          ),
                          TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: _decoration(
                              'Stock quantity',
                              Icons.warehouse_outlined,
                            ),
                            validator: (value) =>
                                _positiveInteger(value, 'Stock'),
                          ),
                        ];
                        return Column(
                          children: [
                            if (compact)
                              ...fields.expand(
                                (field) => [field, const SizedBox(height: 14)],
                              )
                            else ...[
                              Row(
                                children: [
                                  Expanded(child: fields[0]),
                                  const SizedBox(width: 14),
                                  Expanded(child: fields[1]),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: fields[2]),
                                  const SizedBox(width: 14),
                                  Expanded(child: fields[3]),
                                  const SizedBox(width: 14),
                                  Expanded(child: fields[4]),
                                ],
                              ),
                            ],
                            const SizedBox(height: 18),
                            _buildImagePicker(theme),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _isSubmitting ? null : _submit,
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.add_circle_outline),
                                label: Text(
                                  _isSubmitting
                                      ? 'Creating product...'
                                      : 'Create product',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Product images',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add images'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Choose multiple images to show your product from different angles.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (_images.isEmpty)
          InkWell(
            onTap: _pickImages,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              height: 125,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: .25),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 6),
                  const Text('Tap to choose product images'),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _images.asMap().entries.map((entry) {
              return Stack(
                children: [
                  FutureBuilder(
                    future: entry.value.readAsBytes(),
                    builder: (context, snapshot) => Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: snapshot.hasData
                          ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                          : const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => setState(() => _images.removeAt(entry.key)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }
}
