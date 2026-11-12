import '../../domain/entities/care_task.dart';
import '../../domain/entities/regimen_plan.dart';
import '../../domain/entities/resident.dart';
import '../fixtures/resident_fixtures.dart';
import 'care_tasks_repository.dart';

class RegimenGateException implements Exception {
  final int statusCode;
  final String message;

  const RegimenGateException(this.statusCode, this.message);

  @override
  String toString() => message;
}

// [MICROSERVICE_INTEGRATION_POINT]: CareService - Mock Implementation
// Simulates /api/v1/activities endpoints locally when offline or in demo mode.
class MockCareTasksRepository implements CareTasksRepository {
  final Map<String, List<CareTask>> _store = {};
  final Map<String, RegimenPlan> _plans = {};

  MockCareTasksRepository() {
    _initDefaultTasks();
  }

  void _initDefaultTasks() {
    _store['res_margaret'] = [
      const CareTask(
        id: 'task_1',
        residentId: 'res_margaret',
        title: 'Morning Garden Walk',
        description:
            'Gentle walk in the sensory courtyard. Focus on touch, scent of herbs, and bird sounds.',
        time: '09:00 AM',
        category: TaskCategory.physical,
        status: TaskStatus.completed,
        completedBy: 'Nurse Jane',
        completionNote: 'Enjoyed the sunshine, watered tomatoes and roses',
        generationSource: 'baseline_fallback',
      ),
      const CareTask(
        id: 'task_2',
        residentId: 'res_margaret',
        title: 'Folding Laundry',
        description:
            'Folding towels and napkins together. Provides purposeful, tactile coordination and sense of contribution.',
        time: '02:00 PM',
        category: TaskCategory.purposeful,
        status: TaskStatus.pending,
        generationSource: 'baseline_fallback',
      ),
      const CareTask(
        id: 'task_3',
        residentId: 'res_margaret',
        title: 'Music Reminiscence Session',
        description:
            'Listening to 1950s Big Band and jazz records in the sunroom. Sparking reminiscence and emotional ease.',
        time: '04:00 PM',
        category: TaskCategory.social,
        status: TaskStatus.pending,
        generationSource: 'baseline_fallback',
      ),
    ];

    _store['res_robert'] = [
      const CareTask(
        id: 'task_rob_1',
        residentId: 'res_robert',
        title: 'Model Airplane Assembly',
        description: 'Tactile assembly of wooden model wings.',
        time: '10:30 AM',
        category: TaskCategory.purposeful,
        status: TaskStatus.pending,
        generationSource: 'baseline_fallback',
      ),
    ];

    _store['res_dorothy'] = [
      const CareTask(
        id: 'task_dor_1',
        residentId: 'res_dorothy',
        title: 'Herbal Tea Preparation',
        description: 'Selecting dried chamomile and lavender leaves.',
        time: '03:00 PM',
        category: TaskCategory.activity,
        status: TaskStatus.pending,
        generationSource: 'baseline_fallback',
      ),
    ];
  }

  void resetToDemo(String residentId) {
    _plans.clear();
    _initDefaultTasks();
  }

  void setTasks(String residentId, List<CareTask> tasks) {
    final key = ResidentFixtures.toFixtureId(residentId);
    _store[key] = List.from(tasks);
  }

  @override
  Future<List<CareTask>> getTasks(String residentId) async {
    final key = ResidentFixtures.toFixtureId(residentId);
    return List.from(_store[key] ?? _store[residentId] ?? []);
  }

  @override
  Future<CareTask> createTask(String residentId, CareTask task) async {
    final key = ResidentFixtures.toFixtureId(residentId);
    final list = _store.putIfAbsent(key, () => []);
    final newTask = task.copyWith(
      id: task.id.isEmpty
          ? 'task_${DateTime.now().millisecondsSinceEpoch}'
          : task.id,
      residentId: key,
      generationSource: task.generationSource ?? 'manual',
    );
    list.add(newTask);
    return newTask;
  }

  @override
  Future<CareTask> updateTaskStatus({
    required String residentId,
    required String taskId,
    required TaskStatus status,
    String? completedBy,
    String? note,
    String? skipReason,
  }) async {
    final key = ResidentFixtures.toFixtureId(residentId);
    final list = _store[key] ?? _store[residentId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final updated = list[index].copyWith(
          status: status,
          completedBy: completedBy ?? list[index].completedBy,
          completionNote: note ?? list[index].completionNote,
          skipReason: skipReason ?? list[index].skipReason,
        );
        list[index] = updated;
        return updated;
      }
    }

    return CareTask(
      id: taskId,
      residentId: key,
      title: 'Care Task',
      description: '',
      time: '10:00 AM',
      category: TaskCategory.activity,
      status: status,
      completedBy: completedBy,
      completionNote: note,
      skipReason: skipReason,
    );
  }

  @override
  Future<RegimenPlan> generateWeeklyRegimen({
    required Resident resident,
    DateTime? weekStartDate,
    String? refinementInstruction,
    bool autoApply = false,
    bool forceBaseline = false,
  }) async {
    final key = ResidentFixtures.toFixtureId(resident.id);
    final start = weekStartDate ?? DateTime.now().toUtc();
    final planId = 'plan_${DateTime.now().millisecondsSinceEpoch}';
    final source = forceBaseline
        ? RegimenGenerationSource.baselineFallback
        : RegimenGenerationSource.kuboAgent;
    final hasTremors = resident.motorLimitations
        .any((m) => m.toLowerCase().contains('tremor'));
    final primaryInterest = resident.interests.isNotEmpty
        ? resident.interests.first
        : 'familiar life stories';

    final tremorSensitive = hasTremors ||
        (refinementInstruction?.toLowerCase().contains('tremor') ?? false);
    final safetyNote = tremorSensitive
        ? 'Coarse-grip adaptive handles; non-skid silicone mat enforced.'
        : 'Seated ergonomic table posture.';

    final weeklyTemplates = <int, List<Map<String, dynamic>>>{
      1: [
        {
          'time': '09:30 AM',
          'domain': 'Practical Life',
          'title': tremorSensitive
              ? 'Warm Herb & Botanical Tray Sorting'
              : 'Botanical Pressing & Stem Arrangement',
          'description':
              'Purposeful morning sensory arrangement adapted to ${resident.name}.',
          'materials': [
            'Weighted wooden tray',
            'Non-skid silicone mat',
            'Fresh rosemary sprigs',
          ],
          'setup': 'Arrange wide herb stems neatly on a non-skid wooden tray.',
          'steps': [
            'Invite resident to explore herb aroma comfortably seated',
            'Sort stems into two broad linen baskets by scent',
          ],
          'script':
              '"These fresh herbs remind me of your garden—would you like to sort them together?"',
          'dignity': 'Honor pacing without correcting placement.',
          'history': 'Anchored in $primaryInterest and personal biography.',
          'safety': safetyNote,
        },
        {
          'time': '11:30 AM',
          'domain': 'Language',
          'title': 'Illustrated Memory & Career Story Cards',
          'description':
              'Calm 1-to-1 photo reminiscence highlighting lifelong milestones.',
          'materials': [
            'Large-print vintage photo cards',
            'Wooden display stand',
          ],
          'setup': 'Place three clear photos upright on a glare-free mat.',
          'steps': [
            'Present one familiar image at eye level',
            'Pause warmly for stories or reflections',
          ],
          'script': '"Which of these scenes brings back your favorite memory?"',
          'dignity': 'Never quiz names or dates; affirm every memory.',
          'history': 'Connects directly to ${resident.education}.',
          'safety': 'Glare-free matte print in calm lighting.',
        },
        {
          'time': '03:00 PM',
          'domain': 'Sensorial',
          'title': 'Soft Acoustic Melody & Texture Exploration',
          'description':
              'Soothing afternoon rhythm and natural tactile fabrics.',
          'materials': [
            'Soft wool & linen swatches',
            'Warm tea service',
            'Acoustic speaker',
          ],
          'setup': 'Seat comfortably in soft natural light away from noise.',
          'steps': [
            'Play gentle acoustic track at low volume',
            'Offer smooth textile swatches for unhurried sensory touch',
          ],
          'script': '"Shall we listen together while relaxing this afternoon?"',
          'dignity': 'Quiet enjoyment counts as full meaningful engagement.',
          'history': 'Personalized around comforting afternoon rhythms.',
          'safety': 'Soft cotton fabrics with zero choking hazards.',
        },
      ],
      2: [
        {
          'time': '09:30 AM',
          'domain': 'Practical Life',
          'title': tremorSensitive
              ? 'Warm Towels & Linen Folding Basket'
              : 'Linen Table Napkin Folding',
          'description':
              'Familiar purposeful folding using broad, comforting textiles.',
          'materials': [
            'Warm cotton hand towels',
            'Wide woven laundry basket',
            'Non-skid table mat',
          ],
          'setup': 'Place a neat stack of soft hand towels beside the empty basket.',
          'steps': [
            'Demonstrate one simple half-fold together',
            'Place folded towels together in the wide woven basket',
          ],
          'script': '"Could you help me fold these warm towels for the morning?"',
          'dignity': 'Every fold helps; there is no strict fold line required.',
          'history': 'Reflects familiar household rhythms and caring roles.',
          'safety': safetyNote,
        },
        {
          'time': '11:30 AM',
          'domain': 'Sensorial',
          'title': 'Citrus & Lavender Scent Jar Matching',
          'description':
              'Gentle olfactory discrimination using familiar natural aromas.',
          'materials': [
            'Wide-grip ventilated spice jars',
            'Orange peel and lavender sachets',
          ],
          'setup': 'Arrange four large labeled scent jars on a stable tray.',
          'steps': [
            'Offer two calm scents one at a time',
            'Ask which fragrance feels brightest or most soothing',
          ],
          'script': '"Which of these garden scents reminds you of spring?"',
          'dignity': 'Focus on preference rather than guessing exact names.',
          'history': 'Evokes outdoor garden seasons and $primaryInterest.',
          'safety': 'Sealed ventilated jars to prevent accidental ingestion.',
        },
        {
          'time': '03:00 PM',
          'domain': 'Cultural',
          'title': 'Botanical Watercolor Wash & Flower Stamping',
          'description':
              'Relaxed coarse-grip brush painting on thick watercolor stock.',
          'materials': [
            'Thick-handled foam brushes',
            'Heavy textured cardstock',
            'Weighted non-spill water cup',
          ],
          'setup': 'Tape watercolor sheet gently to the table surface.',
          'steps': [
            'Glide wide brush across pre-sketched leaf silhouettes',
            'Admire blended colors once dry',
          ],
          'script': '"Let us paint a few soft garden leaves together."',
          'dignity': 'Praise expressive strokes and choice of colors.',
          'history': 'Honors creative expression and appreciation of beauty.',
          'safety': safetyNote,
        },
      ],
      3: [
        {
          'time': '09:30 AM',
          'domain': 'Math',
          'title': tremorSensitive
              ? 'Weighted Wooden Shape & Season Tray'
              : 'Brass Key & Vintage Token Sorting',
          'description':
              'Clear visual matching of high-contrast tactile wooden pieces.',
          'materials': [
            'Oversized smooth wooden geometric blocks',
            'Two-compartment sorting tray',
          ],
          'setup': 'Separate tray halves with bold dark vs. natural wood tone.',
          'steps': [
            'Invite pairing thick blocks by color or smooth shape',
            'Pause comfortably between placements',
          ],
          'script': '"Let us group the sunlit maple blocks onto this side."',
          'dignity': 'Large pieces build easy confidence without frustration.',
          'history': 'Connects to practical ordering and spatial craft.',
          'safety': safetyNote,
        },
        {
          'time': '11:30 AM',
          'domain': 'Language',
          'title': 'Proverbs, Poetry & Hometown Songs',
          'description':
              'Call-and-response proverbs and familiar verse completion.',
          'materials': [
            'Large-print laminated proverb strips',
            'Felt board',
          ],
          'setup': 'Present two high-contrast proverb halves at eye level.',
          'steps': [
            'Read first half of a beloved proverb slowly',
            'Invite resident to complete or reflect on the phrase',
          ],
          'script': '"You always knew the best sayings—how does this one end?"',
          'dignity': 'Treat hesitation gently by offering the closing word.',
          'history': 'Draws on lifelong reading and cultural wisdom.',
          'safety': 'Large 24pt matte typography reduces visual glare.',
        },
        {
          'time': '03:00 PM',
          'domain': 'Practical Life',
          'title': 'Seasonal Tea Blending & Herb Sachet Tie',
          'description':
              'Tactile filling of wide muslin sachets with dried chamomile.',
          'materials': [
            'Wide-scoop wooden spoon',
            'Pre-stitched muslin pouches',
            'Dried chamomile blossoms',
          ],
          'setup': 'Stabilize pouch inside a weighted stoneware mug for easy scooping.',
          'steps': [
            'Scoop fragrant blossoms gently with wide wooden spoon',
            'Tie pre-looped wide satin ribbon together',
          ],
          'script': '"Would you like to fill a calming sachet for your bedside?"',
          'dignity': 'Support pouch rim steadily whenever needed.',
          'history': 'Anchored in hospitality and herbal traditions.',
          'safety': safetyNote,
        },
      ],
      4: [
        {
          'time': '09:30 AM',
          'domain': 'Practical Life',
          'title': tremorSensitive
              ? 'Smooth Walnut & Cedar Wood Polishing'
              : 'Brass & Silver Heirloom Polishing',
          'description':
              'Rhythmic two-handed wood care using beeswax and soft flannel.',
          'materials': [
            'Rounded walnut serving board',
            'Soft chamois cloth',
            'Food-grade beeswax balm',
          ],
          'setup': 'Anchor wood board on a damp non-skid mat.',
          'steps': [
            'Warm a dab of beeswax onto flannel',
            'Rub slow circular strokes to bring out grain luster',
          ],
          'script': '"Look at how the wood grain warms up when polished gently."',
          'dignity': 'Rhythmic bilateral movement is soothing even if brief.',
          'history': 'Connects to stewardship of cherished household crafts.',
          'safety': safetyNote,
        },
        {
          'time': '11:30 AM',
          'domain': 'Cultural',
          'title': 'World Landmarks & Postcard Atlas Hour',
          'description':
              'Visual journey through iconic cities and scenic postcard art.',
          'materials': [
            'Oversized laminated travel postcards',
            'Wooden easel stand',
          ],
          'setup': 'Prop three vibrant coastal and mountain scenes on an easel.',
          'steps': [
            'Trace rivers or horizons gently while sharing trivia',
            'Invite personal travel or vacation memories',
          ],
          'script': '"If we took a quiet trip tomorrow, which view would you pick?"',
          'dignity': 'Every story or impression is celebrated without correction.',
          'history': 'Honors curiosity about landscapes and $primaryInterest.',
          'safety': 'Seated tabletop arrangement at natural eye level.',
        },
        {
          'time': '03:00 PM',
          'domain': 'Sensorial',
          'title': 'Smooth River Stone & Driftwood Tactile Basket',
          'description':
              'Soothing afternoon sorting of cool smooth stones and warm wood.',
          'materials': [
            'Large palm-sized river pebbles',
            'Smooth driftwood pieces',
            'Felt-lined tray',
          ],
          'setup': 'Arrange large heavy stones safely inside a lipped tray.',
          'steps': [
            'Compare cool smooth stone against warm grained driftwood',
            'Arrange stones in a calm spiral pattern',
          ],
          'script': '"Which of these feels nicest in your palm today?"',
          'dignity': 'Zero right or wrong arrangement.',
          'history': 'Connects with coastal walks and natural serenity.',
          'safety': 'All stones exceed 5cm diameter; zero swallowing risk.',
        },
      ],
      5: [
        {
          'time': '09:30 AM',
          'domain': 'Language',
          'title': 'Morning Weather Board & Seasonal Calendar',
          'description':
              'Orienting morning ritual placing thick magnetic season tiles.',
          'materials': [
            'Large wooden season tiles',
            'Magnetic tabletop calendar easel',
          ],
          'setup': 'Lay out today’s sun/cloud tile and seasonal emblem clearly.',
          'steps': [
            'Look out the window together to notice the sky',
            'Place matching weather and month tile onto the easel',
          ],
          'script': '"What kind of morning sky do we have outside today?"',
          'dignity': 'Gently confirm the date calmly without testing.',
          'history': 'Establishes comforting daily grounding rituals.',
          'safety': safetyNote,
        },
        {
          'time': '11:30 AM',
          'domain': 'Math',
          'title': tremorSensitive
              ? 'Oversized Domino Pattern & Color Pairing'
              : 'Classic Domino Chain Building',
          'description':
              'Visual pattern recognition using extra-large tactile dominoes.',
          'materials': [
            'Jumbo high-contrast wooden dominoes',
            'Felt tabletop mat',
          ],
          'setup': 'Present three face-up starter tiles on dark green felt.',
          'steps': [
            'Match dots or bright color pips side by side',
            'Celebrate completed pattern trails together',
          ],
          'script': '"Shall we find the matching pattern for this tile?"',
          'dignity': 'Use dot colors or patterns flexibly without rigid rules.',
          'history': 'Evokes familiar parlor games with friends and family.',
          'safety': safetyNote,
        },
        {
          'time': '03:00 PM',
          'domain': 'Cultural',
          'title': 'Acoustic Sing-Along & Rhythm Shaker Circle',
          'description':
              'Uplifting musical afternoon with ergonomic percussion.',
          'materials': [
            'Padded loop-handle egg shakers',
            'Curated classic playlist',
          ],
          'setup': 'Seat comfortably with easy reach of padded shaker.',
          'steps': [
            'Listen to timeless melodies from early adulthood',
            'Keep soft beat together on chorus phrases',
          ],
          'script': '"I know you love this melody—care to keep the rhythm?"',
          'dignity': 'Singing, tapping a foot, or smiling are all full participation.',
          'history': 'Anchored in musical favorites and lifelong joy.',
          'safety': 'Light padded percussion; seated posture maintained.',
        },
      ],
      6: [
        {
          'time': '09:30 AM',
          'domain': 'Practical Life',
          'title': 'Succulent Mist Care & Indoor Terrarium Check',
          'description':
              'Gentle nurturing of hardy tabletop greenery with a brass mister.',
          'materials': [
            'Trigger-grip plant mister',
            'Microfiber leaf cloth',
            'Low potted jade plant',
          ],
          'setup': 'Place potted plant solidly inside a deep drip saucer.',
          'steps': [
            'Gently dust broad leaves with soft damp cloth',
            'Offer two soft sprays of mist over soil',
          ],
          'script': '"Our jade plant looks thirsty—shall we tend to it?"',
          'dignity': 'Nurture role fosters autonomy and calm pride.',
          'history': 'Built around $primaryInterest and care for living things.',
          'safety': 'Non-toxic houseplant; saucer catches all moisture.',
        },
        {
          'time': '11:30 AM',
          'domain': 'Sensorial',
          'title': 'Warm Clay & Leaf Impression Pressing',
          'description':
              'Coarse-motor tactile sculpting pressing garden leaves into soft clay.',
          'materials': [
            'Pre-warmed air-dry terracotta clay slab',
            'Broad oak and fern leaves',
          ],
          'setup': 'Place rolled clay disc on parchment over a non-skid mat.',
          'steps': [
            'Press broad leaf gently into smooth clay with palm',
            'Lift leaf slowly to reveal delicate botanical veins',
          ],
          'script': '"Press gently here to capture the pattern of this oak leaf."',
          'dignity': 'Palm pressing succeeds cleanly even with hand tremors.',
          'history': 'Blends outdoor nature appreciation with hands-on craft.',
          'safety': safetyNote,
        },
        {
          'time': '03:00 PM',
          'domain': 'Language',
          'title': 'Family Recipe Scrapbook & Flavor Reminiscence',
          'description':
              'Browsing comforting illustrated cookbooks and spice aromas.',
          'materials': [
            'Large-photo heritage cookbook',
            'Cinnamon stick and vanilla bean',
          ],
          'setup': 'Open cookbook onto a tilted wooden book stand.',
          'steps': [
            'Turn illustrated pages slowly together',
            'Share favorite Sunday dinner or baking memories',
          ],
          'script': '"Which of these comforting dishes was your specialty?"',
          'dignity': 'No cooking precision needed—memory and warmth come first.',
          'history': 'Evokes cherished family meals and kitchen traditions.',
          'safety': 'Seated reading comfort with strong ambient light.',
        },
      ],
      7: [
        {
          'time': '09:30 AM',
          'domain': 'Practical Life',
          'title': 'Sunlit Flower Vase Placement & Ribbon Trim',
          'description':
              'Selecting two hardy blooms and setting a bright table centerpiece.',
          'materials': [
            'Weighted ceramic bud vase',
            'Pre-trimmed sunflowers and eucalyptus',
            'Woven table runner',
          ],
          'setup': 'Half-fill heavy vase with fresh water on a tray.',
          'steps': [
            'Guide thick flower stems smoothly into the wide vase neck',
            'Place finished centerpiece near sunlit window',
          ],
          'script': '"Where would this sunny bouquet look happiest today?"',
          'dignity': 'Celebrate resident aesthetic choices wholeheartedly.',
          'history': 'Connects to $primaryInterest and welcoming home care.',
          'safety': 'Unbreakable or weighted ceramic vase on dry mat.',
        },
        {
          'time': '11:30 AM',
          'domain': 'Cultural',
          'title': 'Sunday Choral Harmonies & Poetry Circle',
          'description':
              'Restful Sunday reflection listening to warm vocal harmonies.',
          'materials': [
            'Large-print lyric cards',
            'Warm chamomile tea cup',
          ],
          'setup': 'Arrange cushioned armchair near natural morning light.',
          'steps': [
            'Listen together to gentle choral or classical tracks',
            'Read aloud one comforting short verse slowly',
          ],
          'script': '"Let us enjoy a peaceful morning verse together."',
          'dignity': 'Calm presence is deeply restorative.',
          'history': 'Honors peaceful Sunday family rhythms.',
          'safety': 'Warm (not hot) beverage served on stable side tray.',
        },
        {
          'time': '03:00 PM',
          'domain': 'Math',
          'title': tremorSensitive
              ? 'Thick Wooden Garden Puzzle & Sequence'
              : 'Chunky Vintage Wooden Jigsaw Frame',
          'description':
              'Relaxed afternoon completion of a 6-piece wooden tray puzzle.',
          'materials': [
            'Knob-handle 6-piece wooden garden puzzle',
            'Non-skid cork backing',
          ],
          'setup': 'Frame 3 border pieces first to create clear visual anchors.',
          'steps': [
            'Offer one chunky knob piece at a time',
            'Admire completed garden scene together',
          ],
          'script': '"Look how cleanly this final blossom piece fits right here."',
          'dignity': 'Knob handles support comfortable grip without strain.',
          'history': 'Wraps up the week with calm tactile achievement.',
          'safety': safetyNote,
        },
      ],
    };

    final items = <CareTask>[];
    for (int day = 1; day <= 7; day++) {
      final templates = weeklyTemplates[day]!;
      for (int idx = 0; idx < templates.length; idx++) {
        final t = templates[idx];
        items.add(
          CareTask(
            id: '${planId}_d${day}_$idx',
            residentId: key,
            planId: planId,
            dayNumber: day,
            title: t['title'] as String,
            description: t['description'] as String,
            time: t['time'] as String,
            category:
                MontessoriTaxonomyMapper.toTaskCategory(t['domain'] as String),
            status: TaskStatus.pending,
            materials: List<String>.from(t['materials'] as List),
            materialsTraySetup: t['setup'] as String,
            steps: List<String>.from(t['steps'] as List),
            scriptPrompt: t['script'] as String,
            dignityTip: t['dignity'] as String,
            historicalConnection: t['history'] as String,
            safetyComfort: t['safety'] as String,
            montessoriDomain: t['domain'] as String,
            generationSource: source.wireValue,
          ),
        );
      }
    }

    final plan = RegimenPlan(
      id: planId,
      externalRegimenId:
          forceBaseline ? null : 'mock_ext_${planId.substring(5)}',
      residentId: key,
      weekStartDate: start,
      generationSource: source,
      planStatus: autoApply ? 'applied' : 'preview',
      synthesisNotes: refinementInstruction != null &&
              refinementInstruction.trim().isNotEmpty
          ? 'Refined regimen per instruction: "$refinementInstruction"'
          : (forceBaseline
              ? 'Clinical 7-day baseline schedule'
              : 'Kubo Montessori Agent synthesized 7-day personalized plan'),
      refinementInstruction: refinementInstruction,
      safetyFlags: hasTremors
          ? const ['Tremor precautions active: wide-grip non-skid tray setup']
          : const [],
      emergencyEscalationRequired: false,
      scorecard: forceBaseline
          ? null
          : const ClinicalScorecard(
              compositeScore: 88,
              cognitiveAlignmentScore: 22,
              physicalAccessibilityScore: 18,
              purposefulEngagementScore: 18,
              safetyControlOfErrorScore: 14,
              modalityBalanceScore: 16,
              feedback:
                  'Well balanced across Practical Life, Language, and Sensorial domains.',
            ),
      generatedAt: DateTime.now().toUtc(),
      items: items,
    );

    _plans[planId] = plan;
    if (autoApply) {
      return applyRegimen(residentId: key, planId: planId);
    }
    return plan;
  }

  @override
  Future<RegimenPlan> refineRegimen({
    required String residentId,
    required String planId,
    required String instruction,
    DateTime? weekStartDate,
  }) async {
    final prev = _plans[planId];
    final fixtureId = ResidentFixtures.toFixtureId(residentId);
    final res = ResidentFixtures.findById(fixtureId);
    final generated = await generateWeeklyRegimen(
      resident: res,
      weekStartDate: weekStartDate ?? prev?.weekStartDate,
      refinementInstruction: instruction,
      autoApply: false,
    );
    return generated;
  }

  @override
  Future<RegimenPlan> applyRegimen({
    required String residentId,
    required String planId,
    DateTime? weekStartDate,
    bool acknowledgeLowScore = false,
  }) async {
    final key = ResidentFixtures.toFixtureId(residentId);
    final plan = _plans[planId];
    if (plan == null) {
      throw const RegimenGateException(404, 'Preview plan not found');
    }
    if (plan.hasCriticalSafetyBlock) {
      throw const RegimenGateException(
        409,
        'Regimen blocked due to critical safety escalation requirement.',
      );
    }
    if (plan.requiresLowScoreConfirmation && !acknowledgeLowScore) {
      throw const RegimenGateException(
        409,
        'Regimen composite score is below 70 and requires explicit confirmation.',
      );
    }

    final existing = _store[key] ?? [];
    final preserved = existing.where((t) {
      final isCompletedOrSkipped = t.status != TaskStatus.pending;
      final isManual = t.generationSource == 'manual';
      return isCompletedOrSkipped || isManual;
    }).toList();

    final dayOneTasks = plan.items.where((t) => (t.dayNumber ?? 1) == 1).toList();
    _store[key] = [...preserved, ...dayOneTasks];

    final applied = RegimenPlan(
      id: plan.id,
      externalRegimenId: plan.externalRegimenId,
      residentId: plan.residentId,
      weekStartDate: weekStartDate ?? plan.weekStartDate,
      generationSource: plan.generationSource,
      planStatus: 'applied',
      synthesisNotes: plan.synthesisNotes,
      refinementInstruction: plan.refinementInstruction,
      safetyFlags: plan.safetyFlags,
      emergencyEscalationRequired: plan.emergencyEscalationRequired,
      scorecard: plan.scorecard,
      generatedAt: plan.generatedAt,
      items: plan.items,
    );
    _plans[planId] = applied;
    return applied;
  }
}
