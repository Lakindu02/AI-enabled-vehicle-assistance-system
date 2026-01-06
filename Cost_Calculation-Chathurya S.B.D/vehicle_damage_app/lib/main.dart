import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'utils/image_processor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
  }

  runApp(const VehicleDamageApp());
}

class VehicleDamageApp extends StatelessWidget {
  const VehicleDamageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Damage Assessment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isLoading = false;
  Map<String, dynamic>? _assessmentResult;

  // Form controllers
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  // API endpoint - Load from environment variables or use default
  String get apiUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000/assess';

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
          _assessmentResult = null; // Clear previous results
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((img) => File(img.path)).toList());
          _assessmentResult = null; // Clear previous results
        });
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _clearAllImages() {
    setState(() {
      _selectedImages.clear();
      _assessmentResult = null;
    });
  }

  Future<void> _assessDamage() async {
    if (_selectedImages.isEmpty) {
      _showError('Please select at least one image');
      return;
    }

    if (_brandController.text.isEmpty ||
        _modelController.text.isEmpty ||
        _yearController.text.isEmpty) {
      _showError('Please fill in all vehicle details');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Extract image paths for background processing
      final imagePaths = _selectedImages.map((img) => img.path).toList();

      // Create assessment request
      final request = AssessmentRequest(
        imagePaths: imagePaths,
        vehicleBrand: _brandController.text,
        vehicleModel: _modelController.text,
        vehicleYear: _yearController.text,
        apiUrl: apiUrl,
        useAi: true,
      );

      // Process assessment in background isolate to avoid blocking UI
      final result = await processDamageAssessment(request);

      setState(() {
        _assessmentResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _cleanMarkdown(String text) {
    // Remove markdown formatting (asterisks, hashtags, etc.)
    return text
        .replaceAll('**', '')  // Remove bold
        .replaceAll('*', '')   // Remove italic/emphasis
        .replaceAll('###', '') // Remove headers
        .replaceAll('##', '')
        .replaceAll('#', '')
        .replaceAll('`', '')   // Remove code blocks
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Damage Assessment'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image selection section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Vehicle Images (${_selectedImages.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedImages.isNotEmpty)
                          TextButton.icon(
                            onPressed: _clearAllImages,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Clear All'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_selectedImages.isEmpty)
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add vehicle photos',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _pickMultipleImages,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Vehicle details form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vehicle Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        hintText: 'e.g., Toyota',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        hintText: 'e.g., Corolla',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        hintText: 'e.g., 2016',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Assess button
            ElevatedButton(
              onPressed: _isLoading ? null : _assessDamage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.blue[300],
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Processing ${_selectedImages.length} image${_selectedImages.length > 1 ? 's' : ''}...',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Assess Damage',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: 16),

            // Results section
            if (_assessmentResult != null) _buildResultsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    final damageDetection = _assessmentResult!['damage_detection'];
    final priceEstimation = _assessmentResult!['price_estimation'];
    final partMapping = _assessmentResult!['part_mapping'];
    final aiValidation = _assessmentResult!['ai_validation'];

    return Column(
      children: [
        // Header Card
        Card(
          elevation: 4,
          color: Colors.green[700],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Assessment Complete',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Detected Damages Card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red[700], size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Detected Damages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (damageDetection['detected_damages'].isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        const Text('No damages detected'),
                      ],
                    ),
                  )
                else
                  ...List.generate(
                    damageDetection['detected_damages'].length,
                    (index) {
                      final damage = damageDetection['detected_damages'][index];
                      final confidence = damageDetection['confidences'][damage];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.circle, size: 8, color: Colors.red[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      damage.replaceAll('_', ' ').toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(confidence * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.build, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Affected Part: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        partMapping['affected_part'].toString().replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Cost Breakdown Card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Cost Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (damageDetection['detected_damages'].isEmpty)
                  const Text('No repair costs')
                else
                  Column(
                    children: [
                      ...List.generate(
                        damageDetection['detected_damages'].length,
                        (index) {
                          final damage = damageDetection['detected_damages'][index];
                          final costPerDamage = priceEstimation['estimated_price'] /
                              damageDetection['detected_damages'].length;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  damage.replaceAll('_', ' ').toUpperCase() + ' repair',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '${priceEstimation['currency']} ${costPerDamage.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(thickness: 2),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL COST',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${priceEstimation['currency']} ${priceEstimation['estimated_price'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // Analysis (if available)
        if (aiValidation != null) ...[
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.purple[700], size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Analysis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (aiValidation['damage_validation'] != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _cleanMarkdown(aiValidation['damage_validation']['analysis'] ?? 'N/A'),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  if (aiValidation['price_explanation'] != null) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Price Explanation:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _cleanMarkdown(aiValidation['price_explanation']['explanation'] ?? 'N/A'),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
