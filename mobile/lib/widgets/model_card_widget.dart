import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/model_response.dart';

class ModelCardWidget extends StatelessWidget {
  final ModelResponse response;
  final bool isLoading;

  const ModelCardWidget({
    Key? key,
    required this.response,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
          if (!isLoading && !response.hasError && response.responseText.isNotEmpty)
            _buildMetrics(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Different gradient for each provider
    final gradient = _getProviderGradient();
    final icon = _getProviderIcon();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  response.modelName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  response.provider,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getProviderGradient() {
    if (response.provider.toLowerCase().contains('openai')) {
      return const LinearGradient(
        colors: [Color(0xFF10A37F), Color(0xFF1A7F64)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (response.provider.toLowerCase().contains('anthropic')) {
      return const LinearGradient(
        colors: [Color(0xFFD97757), Color(0xFFC45A3C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (response.provider.toLowerCase().contains('xai')) {
      return const LinearGradient(
        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    );
  }

  IconData _getProviderIcon() {
    if (response.provider.toLowerCase().contains('openai')) {
      return Icons.auto_awesome;
    } else if (response.provider.toLowerCase().contains('anthropic')) {
      return Icons.psychology_rounded;
    } else if (response.provider.toLowerCase().contains('xai')) {
      return Icons.electric_bolt_rounded;
    }
    return Icons.smart_toy_rounded;
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (response.hasError) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              response.error ?? 'Unknown error',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(
        response.responseText,
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.5,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildMetrics() {
    final formatter = NumberFormat('#,###');
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricItem(
              FontAwesomeIcons.clock,
              '${response.responseTimeMs}ms',
              const Color(0xFF3B82F6),
              const Color(0xFFDBEAFE),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMetricItem(
              FontAwesomeIcons.dollarSign,
              '\$${response.estimatedCost.toStringAsFixed(6)}',
              const Color(0xFF10B981),
              const Color(0xFFD1FAE5),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMetricItem(
              FontAwesomeIcons.hashtag,
              formatter.format(response.totalTokens),
              const Color(0xFF8B5CF6),
              const Color(0xFFEDE9FE),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMetricItem(
              FontAwesomeIcons.arrowsAltH,
              '${formatter.format(response.promptTokens)}/${formatter.format(response.completionTokens)}',
              const Color(0xFFF59E0B),
              const Color(0xFFFEF3C7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(5),
            ),
            child: FaIcon(icon, size: 10, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
