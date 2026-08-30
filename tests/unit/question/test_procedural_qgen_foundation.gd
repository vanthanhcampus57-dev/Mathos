class_name TestProceduralQGenFoundation
extends RefCounted

## Automated test suite covering generic Procedural Question Generation foundation (QGEN-GATE-001..012).

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
	print("[QGEN-GATE-003] Testing identity format & deterministic materialization...")
	
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

	var parsed: Dictionary = QuestionGeneratorIdentity.parse_generated_id(generated_id)
	if not bool(parsed.get("success", false)) or parsed.get("spec_id") != spec_id or parsed.get("variant_key") != variant_key:
		print("[QGEN-GATE-003] FAIL: parse_generated_id failed: " + str(parsed))
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
		var q: Dictionary = gen.generate_question(spec, {}, "variant_k4", {"k": 4})
		ids.append(String(q["question_id"]))

	for id_val in ids:
		if id_val != "qgen_qspec_coin_flip_variant_k4":
			print("[QGEN-GATE-010] FAIL: ID instability detected: " + id_val)
			return false

	print("[QGEN-GATE-010] PASS")
	return true

static func test_qgen_011_collision_protection() -> bool:
	print("[QGEN-GATE-011] Testing ID collision protection & static vs generated ID separation...")
	
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://content")
	var catalog: ValidatedCatalog = repo.get_catalog()
	
	for q_id in ["q_d1_01_1", "q_d1_01_2", "q_d1_05_5", "q_d4_05_5"]:
		if QuestionGeneratorIdentity.is_generated_id(q_id):
			print("[QGEN-GATE-011] FAIL: Static question ID detected with generated prefix: " + q_id)
			return false

	var gen_id1: String = QuestionGeneratorIdentity.build_generated_id("spec_a", "v1")
	var gen_id2: String = QuestionGeneratorIdentity.build_generated_id("spec_a", "v1")
	var gen_id3: String = QuestionGeneratorIdentity.build_generated_id("spec_a", "v2")

	if gen_id1 != gen_id2:
		print("[QGEN-GATE-011] FAIL: Identical spec/variant did not collide to same ID")
		return false

	if gen_id1 == gen_id3:
		print("[QGEN-GATE-011] FAIL: Distinct variants generated colliding IDs")
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
