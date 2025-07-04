import 'package:flutter/material.dart';
import 'package:nirva_app/stress_level_card.dart';
import 'package:nirva_app/energy_level_card.dart';
import 'package:nirva_app/mood_tracking_card.dart';
import 'package:nirva_app/awake_time_allocation_card.dart';
import 'package:nirva_app/mood_score_card.dart';
import 'package:nirva_app/social_map_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _createBody());
  }

  Widget _createBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMoodScoreCardAndStressLevelCard(),
            const SizedBox(height: 16),
            _buildEnergyLevelCard(),
            const SizedBox(height: 16),
            _buildMoodTrackingCard(),
            const SizedBox(height: 16),
            _buildAwakeTimeAllocationCard(),
            const SizedBox(height: 16),
            _buildSocialMapCard(),
            // const SizedBox(height: 16),
            // _buildTodaysHighlightsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodScoreCardAndStressLevelCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [MoodScoreCard(), StressLevelCard()],
    );
  }

  Widget _buildEnergyLevelCard() {
    return const EnergyLevelCard();
  }

  Widget _buildMoodTrackingCard() {
    return const MoodTrackingCard();
  }

  Widget _buildAwakeTimeAllocationCard() {
    return const AwakeTimeAllocationCard();
  }

  Widget _buildSocialMapCard() {
    return const SocialMapCard();
    //return const SocialMapCard();
  }

  // Widget _buildTodaysHighlightsCard() {
  //   return TodayHighlightsCard();
  // }
}
