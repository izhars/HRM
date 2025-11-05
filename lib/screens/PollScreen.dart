import 'package:flutter/material.dart';
import '../services/PollService.dart';
import 'PollResultsScreen.dart';

class PollScreen extends StatefulWidget {
  const PollScreen({Key? key}) : super(key: key);

  @override
  State<PollScreen> createState() => _PollScreenState();
}

class _PollScreenState extends State<PollScreen>
    with SingleTickerProviderStateMixin {
  final PollService _pollService = PollService();
  bool _loading = true;
  List<dynamic> _polls = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchPolls();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchPolls() async {
    try {
      setState(() => _loading = true);
      final polls = await _pollService.fetchPolls();
      setState(() {
        _polls = polls;
        _loading = false;
      });
      _animationController.forward();
    } catch (e) {
      debugPrint('Error fetching polls: $e');
      setState(() => _loading = false);
      _showErrorSnackBar('Failed to load polls');
    }
  }

  Future<void> _vote(String pollId, int optionIndex) async {
    try {
      final result = await _pollService.votePoll(pollId, optionIndex);
      if (result['success'] == true) {
        _showSuccessSnackBar(result['message'] ?? 'Vote recorded successfully');
        await _fetchPolls(); // Refresh polls
      }
    } catch (e) {
      debugPrint('Vote error: $e');
      _showErrorSnackBar('Failed to submit vote');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Community Polls',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE0E0E0)),
        ),
      ),
      body: _loading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
          ),
          SizedBox(height: 16),
          Text(
            'Loading polls...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_polls.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _fetchPolls,
        color: Colors.indigo,
        backgroundColor: Colors.white,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _polls.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildPollCard(_polls[index]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.poll_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No polls available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new polls!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to your existing PollScreen class
  Widget _buildPollCard(Map<String, dynamic> poll) {
    final options = poll['options'] as List<dynamic>;
    final hasVoted = poll['hasVoted'] == true;
    final totalVotes = poll['totalVotes'] ?? 0;
    final isExpired = _isPollExpired(poll['expiresAt']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPollHeader(poll),
            const SizedBox(height: 16),
            _buildPollOptions(options, poll['_id'], hasVoted, isExpired, totalVotes),
            const SizedBox(height: 16),
            _buildPollFooter(poll, totalVotes, hasVoted, isExpired),
            if (totalVotes > 0) ...[
              const SizedBox(height: 12),
              _buildResultsButton(poll),
            ],
          ],
        ),
      ),
    );
  }

// Add this new method to your existing PollScreen class
  Widget _buildResultsButton(Map<String, dynamic> poll) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PollResultsScreen(
                pollId: poll['_id'],
                pollQuestion: poll['question'] ?? 'Untitled Poll',
              ),
            ),
          );
        },
        icon: const Icon(Icons.bar_chart, size: 18),
        label: const Text('View Results'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.indigo,
          side: BorderSide(color: Colors.indigo.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }


  Widget _buildPollHeader(Map<String, dynamic> poll) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.poll,
            color: Colors.indigo[600],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                poll['question'] ?? 'Untitled Poll',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (poll['expiresAt'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Expires: ${_formatDate(poll['expiresAt'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPollOptions(List<dynamic> options, String pollId,
      bool hasVoted, bool isExpired, int totalVotes) {
    return Column(
      children: options.asMap().entries.map((entry) {
        final optionIndex = entry.key;
        final option = entry.value;
        final optionText = option['text'] ?? 'Option ${optionIndex + 1}';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildOptionButton(
            optionText,
            optionIndex,
            pollId,
            hasVoted,
            isExpired,
            totalVotes,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionButton(String text, int index, String pollId,
      bool hasVoted, bool isExpired, int totalVotes) {
    final isDisabled = hasVoted || isExpired;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDisabled
              ? Colors.grey[300]!
              : Colors.indigo.withOpacity(0.3),
          width: 1.5,
        ),
        gradient: isDisabled
            ? null
            : LinearGradient(
          colors: [
            Colors.indigo.withOpacity(0.05),
            Colors.indigo.withOpacity(0.02),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDisabled ? null : () => _vote(pollId, index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? Colors.grey[400]
                        : Colors.indigo,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDisabled
                          ? Colors.grey[600]
                          : Colors.black87,
                    ),
                  ),
                ),
                if (isDisabled)
                  Icon(
                    hasVoted ? Icons.check_circle : Icons.schedule,
                    color: hasVoted ? Colors.green : Colors.grey[400],
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPollFooter(Map<String, dynamic> poll, int totalVotes,
      bool hasVoted, bool isExpired) {
    return Row(
      children: [
        Icon(
          Icons.how_to_vote,
          size: 16,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 6),
        Text(
          '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (hasVoted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Voted',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else if (isExpired)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Expired',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  bool _isPollExpired(String? expiresAt) {
    if (expiresAt == null) return false;
    try {
      final expiry = DateTime.parse(expiresAt);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return false;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = date.difference(now);

      if (difference.inDays > 0) {
        return '${difference.inDays}d left';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h left';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m left';
      } else {
        return 'Expired';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }
}
