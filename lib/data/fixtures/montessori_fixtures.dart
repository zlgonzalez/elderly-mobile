import '../../domain/entities/montessori_activity.dart';

class MontessoriFixtures {
  static final List<MontessoriActivity> activities = [
    // Practical Life
    const MontessoriActivity(
      id: 'act_folding_linens',
      title: 'Folding Warm Linens & Towels',
      category: MontessoriCategory.practicalLife,
      summary: 'Folding freshly warmed washcloths or hand towels at an unhurried, rhythmic pace.',
      durationMinutes: 15,
      materials: ['Basket of warm hand towels or napkins', 'Flat table with ample room'],
      whyItMatters: 'Practical life tasks give a strong sense of purpose and contribution to household life. Folding utilizes familiar muscle memory, maintaining hand flexibility and bilateral coordination.',
      steps: [
        'Place the basket of freshly warmed towels on the table beside the resident.',
        'Take one towel and gently demonstrate folding it in half: "Would you like to help me fold these towels for tea time?"',
        'Hand a towel to the resident and fold side by side, allowing them to lead the pace.',
        'Place each completed towel in the stack together with genuine appreciation: "Thank you, Margaret, this is wonderful help."',
      ],
      dignityTip: 'Never refold or correct a towel in front of the resident. The therapeutic value is in the purposeful participation, not mechanical perfection.',
    ),
    const MontessoriActivity(
      id: 'act_arranging_flowers',
      title: 'Arranging Cut Garden Flowers',
      category: MontessoriCategory.practicalLife,
      summary: 'Trimming and arranging seasonal blossoms into small water vases for dining tables.',
      durationMinutes: 20,
      materials: ['Cut flower stems (roses, daisies, lavender)', 'Child-safe shears or pre-trimmed stems', 'Small vases or jars with water'],
      whyItMatters: 'Connects the resident to nature, seasonal cycles, and creative aesthetics. Engages fine motor control and spatial awareness while beautifying shared spaces.',
      steps: [
        'Arrange the blossoms and empty vases on a waterproof mat or tray.',
        'Invite the resident to touch and smell each blossom, discussing memories of past gardens.',
        'Offer stems one at a time and ask where each bloom might like to rest in the vase.',
        'Place the completed arrangement on the resident\'s bedside table or dining table.',
      ],
      dignityTip: 'Focus on the sensory pleasure of petals and fragrances rather than strict floral rules.',
    ),
    const MontessoriActivity(
      id: 'act_table_setting',
      title: 'Afternoon Place Setting',
      category: MontessoriCategory.practicalLife,
      summary: 'Setting placemats, cloth napkins, and silverware using a fabric template guide.',
      durationMinutes: 15,
      materials: ['Placemat with stitched cutlery outlines', 'Cloth napkins', 'Lightweight utensils'],
      whyItMatters: 'Reinforces daily orientation and sequencing. Prepares the body and appetite for upcoming meals.',
      steps: [
        'Lay the placemat guide flat before the resident.',
        'Offer one utensil at a time: "Where does the soup spoon like to sit?"',
        'Celebrate completion and invite them to sit for tea.',
      ],
      dignityTip: 'Use a template mat to provide subtle scaffolding without verbal commands.',
    ),

    // Cognitive
    const MontessoriActivity(
      id: 'act_song_matching',
      title: 'Classic Song Lyric Completion',
      category: MontessoriCategory.cognitive,
      summary: 'Reading first lines of beloved 1940s-60s classics and completing the famous chorus together.',
      durationMinutes: 20,
      materials: ['Large-print laminated lyric prompt cards (e.g. "Over the...", "You are my...")'],
      whyItMatters: 'Musical memory often remains intact long after other verbal memories decline. Tapping into preserved neural pathways brings immense joy and verbal fluency.',
      steps: [
        'Read the first line of a card clearly and melodically: "Somewhere over the..."',
        'Pause and smile, waiting warmly for the resident to complete the phrase: "...Rainbow!"',
        'Hum or sing the next bars together if inspired.',
      ],
      dignityTip: 'If a word doesn\'t come immediately, gently sing the line together without drawing attention to hesitation.',
    ),
    const MontessoriActivity(
      id: 'act_botanical_cards',
      title: 'Botanical Matching & Sorting Cards',
      category: MontessoriCategory.cognitive,
      summary: 'Matching vibrant picture cards of familiar garden plants, birds, or vintage teacups.',
      durationMinutes: 15,
      materials: ['Set of 8-12 large high-contrast photographic botanical cards'],
      whyItMatters: 'Stimulates visual discrimination, object naming, and categorized recall in a relaxing, low-stakes format.',
      steps: [
        'Lay out 3 distinct cards face up on the table.',
        'Hand a matching pair card to the resident: "Can you find the yellow rose that looks like this one?"',
        'Discuss any associations: "Did you ever have yellow roses in your Scarborough garden?"',
      ],
      dignityTip: 'Keep the number of cards low (3-5 at a time) to prevent sensory overwhelm.',
    ),

    // Creative
    const MontessoriActivity(
      id: 'act_watercolour_flowers',
      title: 'Watercolour Blossom Washes',
      category: MontessoriCategory.creative,
      summary: 'Painting gentle watercolor washes over embossed or wax-resist flower outlines.',
      durationMinutes: 25,
      materials: ['Thick watercolour paper with wax outline', 'Watercolour palette', 'Wide soft-bristle brush', 'Water jar'],
      whyItMatters: 'Wax-resist outlines ensure every brushstroke yields a beautiful result, building confidence. Encourages free emotional expression without fear of mistakes.',
      steps: [
        'Dip the brush into water and select a pastel color together.',
        'Stroke freely across the paper; watch the flower outline magically repel the paint.',
        'Encourage mixing hues: "Look how soft the lilac and rose tones look together."',
      ],
      dignityTip: 'Frame or display the finished painting promptly in their room.',
    ),
    const MontessoriActivity(
      id: 'act_clay_pinch_pots',
      title: 'Air-Dry Clay Pinch Bowls',
      category: MontessoriCategory.creative,
      summary: 'Kneading and shaping soft non-toxic terracotta clay into small trinket dishes.',
      durationMinutes: 20,
      materials: ['Non-toxic air-dry clay ball', 'Textured lace or leaves for stamping'],
      whyItMatters: 'Tactile resistance of clay strengthens finger joints and provides soothing sensory grounding.',
      steps: [
        'Warm the clay between hands and roll into a ball.',
        'Press thumbs into center to form a gentle hollow bowl.',
        'Optionally press a fresh leaf onto the rim to emboss delicate vein textures.',
      ],
      dignityTip: 'Work alongside them on your own pinch pot to make it a shared creative partnership.',
    ),

    // Sensory
    const MontessoriActivity(
      id: 'act_lavender_scent',
      title: 'Lavender Scent Bags & Aromatherapy',
      category: MontessoriCategory.sensory,
      summary: 'Filling small breathable organza sachets with fragrant dried French lavender buds.',
      durationMinutes: 15,
      materials: ['Bowl of dried lavender buds', 'Small wooden spoon or scoop', 'Organza drawstring sachets'],
      whyItMatters: 'Olfactory stimulation stimulates the limbic system, activating deep emotional comfort and reducing anxiety or agitation.',
      steps: [
        'Rub a few lavender buds between palms and inhale deeply together.',
        'Use the wooden spoon to scoop buds into the small sachet.',
        'Pull the satin drawstrings shut and tuck the sachet into Margaret\'s pillowcase or cardigan pocket.',
      ],
      dignityTip: 'Observe non-verbal cues (relaxed shoulders, deeper breathing) to gauge soothing effect.',
    ),
    const MontessoriActivity(
      id: 'act_seed_sorting',
      title: 'Seed Sorting & Planting Tray',
      category: MontessoriCategory.sensory,
      summary: 'Sorting large seeds (sunflower, pumpkin, bean) into divided natural wooden bowls.',
      durationMinutes: 20,
      materials: ['Divided wooden tray', 'Large dried sunflower seeds, runner beans, and acorn squash seeds'],
      whyItMatters: 'Pincer grasp exercise that reinforces tactile differentiation while connecting directly to a love for planting and gardening.',
      steps: [
        'Present the mixed seed bowl and three small empty cups.',
        'Gently pick up a large white bean: "These smooth beans feel so lovely. Let\'s gather them in this cup."',
        'Sort together while reminiscing about spring planting seasons.',
      ],
      dignityTip: 'Use extra large seeds to avoid frustration and ensure ease of manipulation.',
    ),
    const MontessoriActivity(
      id: 'act_fabric_sorting',
      title: 'Textured Fabric Exploration',
      category: MontessoriCategory.sensory,
      summary: 'Exploring swatches of velvet, silk, tweed, and corduroy in a tactile treasure box.',
      durationMinutes: 15,
      materials: ['Box of diverse fabric swatches (velvet, silk, wool, satin)'],
      whyItMatters: 'Tactile discrimination relieves restlessness and engages tactile receptors with comforting textures.',
      steps: [
        'Hand a velvet swatch: "Feel how soft and deep this fabric is."',
        'Pair swatches into "smooth" vs "fuzzy" piles.',
      ],
      dignityTip: 'Connect textures to familiar items like winter coats or wedding dresses.',
    ),

    // Social
    const MontessoriActivity(
      id: 'act_tea_ritual',
      title: 'Afternoon Tea Ritual & Story Circle',
      category: MontessoriCategory.social,
      summary: 'Preparing and enjoying chamomile or Earl Grey tea with porcelain cups and conversation cards.',
      durationMinutes: 30,
      materials: ['Teapot with warm herbal tea', 'Porcelain cups and saucers', 'Small plate of lemon biscuits'],
      whyItMatters: 'Maintains adult social dignity, host/guest dynamics, and reciprocal warmth.',
      steps: [
        'Invite Margaret to pour milk or add a sugar cube with small tongs.',
        'Raise cups together: "To good company and sunny afternoons."',
        'Ask open-ended conversational prompts: "What was your favourite family Sunday tradition?"',
      ],
      dignityTip: 'Treat the resident as the esteemed host of the afternoon tea.',
    ),
    const MontessoriActivity(
      id: 'act_hand_massage',
      title: 'Gentle Rosemary & Almond Hand Massage',
      category: MontessoriCategory.social,
      summary: 'Warm scented lotion massage on hands and wrists accompanied by soft soothing music.',
      durationMinutes: 15,
      materials: ['Warm sweet almond lotion with a hint of rosemary or citrus', 'Warm damp washcloth'],
      whyItMatters: 'Compassionate touch communicates safety, unconditional acceptance, and reduces cortisol levels.',
      steps: [
        'Ask permission warmly: "Would you like a gentle warm lotion hand massage, Margaret?"',
        'Warm lotion between your palms, then stroke the back of the resident\'s hands with gentle upward pressure.',
        'Softly circle the palm and each finger, maintaining gentle eye contact.',
      ],
      dignityTip: 'Continuously check in with facial expressions to ensure pressure is soothing.',
    ),
  ];

  static List<MontessoriActivity> getByCategory(MontessoriCategory? category) {
    if (category == null) return activities;
    return activities.where((a) => a.category == category).toList();
  }

  static MontessoriActivity? findById(String id) {
    try {
      return activities.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
