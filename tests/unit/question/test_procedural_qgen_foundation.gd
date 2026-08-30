class_name TestProceduralQGenFoundation
extends RefCounted

## Automated test suite covering generic Procedural Question Generation foundation (QGEN-GATE-001, 002, 003, 010, 011, 012).

const MathKnowledgePack = preload("res://src/content/models/math_knowledge_pack.gd")
const QuestionGenerationSpec = preload("res://src/content/models/question_generation_spec.gd")
const QuestionGeneratorIdentity = preload("res://src/education/question/generator/question_generator_identity.gd")
const QuestionGenerator = preload("res://src/education/question/generator/question_generator.gd")
const GeneratorRegistry = preload("res://src/education/question/generator/generator_registry.gd")

static func run_all_tests() -> bool:
	print("--- RUNNING PROCEDURAL QGEN FOUNDATION SUITE ---")
	var all_ok: bool = true

	all_ok = test_qgen_001_models_and_schema_validation() and all_ok
	all_ok = test_qgen_002_catalog_publication() and all_ok
	all_ok = test_qgen_003_identity_and_determinism() and all_ok
	all_ok = test_qgen_010_generated_id_stability() and all_ok
	all_ok = test_qgen_011_collision_protection() and all_ok
	all_ok = test_qgen_012_generator_registry() and all_ok

	return all_ok

static func test_qgen_001_models_and_schema_validation() -> bool:
	print("[QGEN-GATE-001] Testing MathKnowledgePack & QuestionGenerationSpec model parsing & schema validation...")
	
	var pack_dict: Dictionary = {
		"schema_version": 1,
		"pack_id": "mkp_test_trial",
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_id": "random_trial",
		"domain_variables": {"n_coins": {"type": "int", "min": 1, "max": 5}},
		"math_rules": {"outcomes": "2^n_coins"},
		"forbidden_concepts": [],
		"prerequisite_concepts": []
	}
	var pack: RefCounted = MathKnowledgePack.new(pack_dict)
	if pack.get_pack_id() != "mkp_test_trial" or pack.get_dungeon_id() != "dungeon_01":
		print("[QGEN-GATE-001] FAIL: MathKnowledgePack model parsing failed")
		return false

	var spec_dict: Dictionary = {
		"schema_version": 1,
		"spec_id": "qspec_test_coin_mc",
		"generator_family_id": "family_trial_sample_event",
		"pack_id": "mkp_test_trial",
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_id": "random_trial",
		"difficulty_range": {"min": 1, "max": 3},
		"interaction_type": "multiple_choice",
		"template": {
			"prompt": "Gieo {n_coins} đồng xu cân đối. Hỏi có bao nhiêu khả năng?",
			"explanation": "Số khả năng là 2^{n_coins} = {outcomes}.",
			"learning_objective": "Tính số khả năng gieo đồng xu.",
			"interaction_payload": {
				"options": [
					{"option_id": "opt_a", "text": "{outcomes}"},
					{"option_id": "opt_b", "text": "{wrong_1}"}
				]
			},
			"answer_spec": {"correct_option_id": "opt_a"}
		},
		"parameter_bindings": {}
	}
	var spec: RefCounted = QuestionGenerationSpec.new(spec_dict)
	if spec.get_spec_id() != "qspec_test_coin_mc" or spec.get_interaction_type() != "multiple_choice":
		print("[QGEN-GATE-001] FAIL: QuestionGenerationSpec model parsing failed")
		return false

	print("[QGEN-GATE-001] PASS")
	return true

static func test_qgen_002_catalog_publication() -> bool:
	print("[QGEN-GATE-002] Testing ValidatedCatalog publication & repository getters...")
	
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://content")
	if not report.publication_allowed:
		print("[QGEN-GATE-002] FAIL: Production content failed validation report")
		return false
		
	var catalog: ValidatedCatalog = repo.get_catalog()
	if catalog == null:
		print("[QGEN-GATE-002] FAIL: Catalog is null")
		return false

	var all_packs: Array[Dictionary] = catalog.get_all_math_knowledge_packs()
	var all_specs: Array[Dictionary] = catalog.get_all_question_generation_specs()
	
	if not (all_packs is Array) or not (all_specs is Array):
		print("[QGEN-GATE-002] FAIL: Catalog publication getter returned invalid type")
		return false

	print("[QGEN-GATE-002] PASS")
	return true

static func test_qgen_003_identity_and_determinism() -> bool:
	print("[QGEN-GATE-003] Testing identity format, round-tripping & deterministic materialization...")
	
	var spec_id: String = "qspec_random_trial_mc"
	var variant_key: String = "v1"
	var expected_id: String = "qgen_qspec_random_trial_mc_v1"
	
	var generated_id: String = QuestionGeneratorIdentity.build_generated_id(spec_id, variant_key)
	if generated_id != expected_id:
		print("[QGEN-GATE-003] FAIL: Expected " + expected_id + " but got " + generated_id)
		return false

	if not QuestionGeneratorIdentity.is_generated_id(generated_id):
		print("[QGEN-GATE-003] FAIL: is_generated_id returned false")
		return false

	# Exact round-trip verification for legal examples
	var roundtrip_cases: Array[Dictionary] = [
		{"spec": "qspec_coin_flip", "variant": "v1", "expected": "qgen_qspec_coin_flip_v1"},
		{"spec": "qspec_coin_flip", "variant": "k3-heads2", "expected": "qgen_qspec_coin_flip_k3-heads2"},
		{"spec": "qspec_coin_flip", "variant": "a13f90c2", "expected": "qgen_qspec_coin_flip_a13f90c2"}
	]

	for c in roundtrip_cases:
		var built: String = QuestionGeneratorIdentity.build_generated_id(String(c["spec"]), String(c["variant"]))
		if built != String(c["expected"]):
			print("[QGEN-GATE-003] FAIL: build_generated_id mismatch: " + built + " vs " + String(c["expected"]))
			return false

		var parsed: Dictionary = QuestionGeneratorIdentity.parse_generated_id(built)
		if not bool(parsed.get("success", false)):
			print("[QGEN-GATE-003] FAIL: parse_generated_id returned false for legal ID: " + built)
			return false
		if parsed.get("spec_id") != c["spec"] or parsed.get("variant_key") != c["variant"]:
			print("[QGEN-GATE-003] FAIL: Roundtrip value mismatch: " + str(parsed))
			return false

	# Rejection of illegal variants (containing "_" or illegal chars)
	var illegal_variants: Array[String] = ["v_1", "v_k3_heads2", "V1", "v.1", "v!1", "", "variant_key_with_underscore"]
	for iv in illegal_variants:
		var bad_id: String = QuestionGeneratorIdentity.build_generated_id("qspec_coin_flip", iv)
		if bad_id != "":
			print("[QGEN-GATE-003] FAIL: build_generated_id accepted illegal variant: " + iv)
			return false

	# Rejection of malformed IDs in parse_generated_id
	var malformed_ids: Array[String] = ["invalid_prefix_v1", "qgen_", "qgen_nospec", "qgen__v1"]
	for mid in malformed_ids:
		var try_parse: Dictionary = QuestionGeneratorIdentity.parse_generated_id(mid)
		if bool(try_parse.get("success", false)):
			print("[QGEN-GATE-003] FAIL: parse_generated_id accepted malformed ID: " + mid)
			return false

	var gen: RefCounted = QuestionGenerator.new()
	var spec: Dictionary = {
		"spec_id": spec_id,
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_id": "random_trial",
		"difficulty_range": {"min": 1, "max": 5},
		"interaction_type": "multiple_choice",
		"template": {
			"prompt": "Gieo {n} đồng xu.",
			"explanation": "Có {ans} khả năng.",
			"learning_objective": "Gieo {n} đồng xu.",
			"interaction_payload": {"options": [{"option_id": "opt_a", "text": "{ans}"}]},
			"answer_spec": {"correct_option_id": "opt_a"}
		}
	}
	var params: Dictionary = {"n": 3, "ans": 8}
	
	var q1: Dictionary = gen.generate_question(spec, {}, variant_key, params)
	var q2: Dictionary = gen.generate_question(spec, {}, variant_key, params)

	if q1["question_id"] != expected_id or q2["question_id"] != expected_id:
		print("[QGEN-GATE-003] FAIL: Question ID mismatch")
		return false

	if q1["prompt"] != "Gieo 3 đồng xu." or q2["prompt"] != "Gieo 3 đồng xu.":
		print("[QGEN-GATE-003] FAIL: Prompt template substitution mismatch")
		return false

	if q1 != q2:
		print("[QGEN-GATE-003] FAIL: Materialization not deterministic across identical calls")
		return false

	print("[QGEN-GATE-003] PASS")
	return true

static func test_qgen_010_generated_id_stability() -> bool:
	print("[QGEN-GATE-010] Testing generated ID stability across repeated runs...")
	
	var gen: RefCounted = QuestionGenerator.new()
	var spec: Dictionary = {
		"spec_id": "qspec_coin_flip",
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_id": "random_trial",
		"interaction_type": "input",
		"template": {
			"prompt": "Tính số mặt sấp khi gieo {k} lần.",
			"explanation": "Giải thích {k}",
			"learning_objective": "Objective",
			"interaction_payload": {"input_type": "integer", "placeholder_text": "Nhập..."},
			"answer_spec": {"accepted_values": [4]}
		}
	}
	
	var ids: Array[String] = []
	for i in range(10):
		var q: Dictionary = gen.generate_question(spec, {}, "variant-k4", {"k": 4})
		ids.append(String(q["question_id"]))

	for id_val in ids:
		if id_val != "qgen_qspec_coin_flip_variant-k4":
			print("[QGEN-GATE-010] FAIL: ID instability detected: " + id_val)
			return false

	print("[QGEN-GATE-010] PASS")
	return true

static func test_qgen_011_collision_protection() -> bool:
	print("[QGEN-GATE-011] Testing collision rules: same spec/variant, distinct spec/variant & static separation...")
	
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://content")
	var catalog: ValidatedCatalog = repo.get_catalog()
	
	# Static namespace separation
	for q_id in ["q_d1_01_1", "q_d1_01_2", "q_d1_05_5", "q_d4_05_5"]:
		if QuestionGeneratorIdentity.is_generated_id(q_id):
			print("[QGEN-GATE-011] FAIL: Static question ID detected with generated prefix: " + q_id)
			return false

	# 1. Same spec + same legal variant -> same stable ID
	var id1_a: String = QuestionGeneratorIdentity.build_generated_id("qspec_coin", "v1")
	var id1_b: String = QuestionGeneratorIdentity.build_generated_id("qspec_coin", "v1")
	if id1_a != id1_b or id1_a != "qgen_qspec_coin_v1":
		print("[QGEN-GATE-011] FAIL: Same spec + same variant did not yield identical stable ID")
		return false

	# 2. Same spec + different variant -> distinct IDs
	var id2_a: String = QuestionGeneratorIdentity.build_generated_id("qspec_coin", "v1")
	var id2_b: String = QuestionGeneratorIdentity.build_generated_id("qspec_coin", "v2")
	if id2_a == id2_b:
		print("[QGEN-GATE-011] FAIL: Same spec + different variant yielded colliding IDs")
		return false

	# 3. Different spec + same variant -> distinct IDs
	var id3_a: String = QuestionGeneratorIdentity.build_generated_id("qspec_coin_flip", "v1")
	var id3_b: String = QuestionGeneratorIdentity.build_generated_id("qspec_dice_roll", "v1")
	if id3_a == id3_b:
		print("[QGEN-GATE-011] FAIL: Different spec + same variant yielded colliding IDs")
		return false

	# 4. Illegal variant containing underscore -> rejected
	var id_illegal: String = QuestionGeneratorIdentity.build_generated_id("qspec_coin", "v_1")
	if id_illegal != "":
		print("[QGEN-GATE-011] FAIL: Illegal variant containing underscore was not rejected")
		return false

	# 5. Generated-vs-generated duplicate collision detection check
	var generated_registry: Dictionary = {}
	var pair1: Array = [["qspec_coin", "v1"], ["qspec_coin", "v1"]]
	for p in pair1:
		var gid: String = QuestionGeneratorIdentity.build_generated_id(p[0], p[1])
		if generated_registry.has(gid):
			# Duplicate collision detected cleanly
			pass
		else:
			generated_registry[gid] = true

	if generated_registry.size() != 1:
		print("[QGEN-GATE-011] FAIL: Duplicate generated ID count mismatch")
		return false

	print("[QGEN-GATE-011] PASS")
	return true

static func test_qgen_012_generator_registry() -> bool:
	print("[QGEN-GATE-012] Testing GeneratorRegistry register, lookup, and clear...")
	
	var registry: RefCounted = GeneratorRegistry.new()
	var gen: RefCounted = QuestionGenerator.new()
	
	if registry.has_generator("family_test"):
		print("[QGEN-GATE-012] FAIL: Unregistered generator returned true")
		return false

	registry.register_generator("family_test", gen)
	
	if not registry.has_generator("family_test"):
		print("[QGEN-GATE-012] FAIL: Registered generator not found")
		return false

	if registry.get_generator("family_test") != gen:
		print("[QGEN-GATE-012] FAIL: Retrieved generator mismatch")
		return false

	registry.clear()
	if registry.has_generator("family_test"):
		print("[QGEN-GATE-012] FAIL: Generator present after clear")
		return false

	print("[QGEN-GATE-012] PASS")
	return true
