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
	print("[QGEN-GATE-003] Testing canonical parameter derivation, round-tripping & materialization...")

	# Test A: Order Independence in Canonical Derivation
	var tuple_a1: Dictionary = {"k": 3, "heads": 2}
	var tuple_a2: Dictionary = {"heads": 2, "k": 3}

	var var_a1: String = QuestionGeneratorIdentity.derive_variant_key(tuple_a1)
	var var_a2: String = QuestionGeneratorIdentity.derive_variant_key(tuple_a2)

	if var_a1 != var_a2:
		print("[QGEN-GATE-003] FAIL: Parameter insertion order produced different variant_key: " + var_a1 + " vs " + var_a2)
		return false

	var gen_id_a1: String = QuestionGeneratorIdentity.build_generated_id_from_params("qspec_random_trial_mc", tuple_a1)
	var gen_id_a2: String = QuestionGeneratorIdentity.build_generated_id_from_params("qspec_random_trial_mc", tuple_a2)

	if gen_id_a1 != gen_id_a2:
		print("[QGEN-GATE-003] FAIL: Parameter insertion order produced different generated_id")
		return false

	# Test B: Nested Dictionary Insertion Order Independence
	var nested_1: Dictionary = {"outer": {"b": 2, "a": 1}}
	var nested_2: Dictionary = {"outer": {"a": 1, "b": 2}}
	if QuestionGeneratorIdentity.derive_variant_key(nested_1) != QuestionGeneratorIdentity.derive_variant_key(nested_2):
		print("[QGEN-GATE-003] FAIL: Nested dictionary key order affected derivation")
		return false

	# Test C: Array Element Order Significance
	var arr_1: Dictionary = {"list": [1, 2]}
	var arr_2: Dictionary = {"list": [2, 1]}
	if QuestionGeneratorIdentity.derive_variant_key(arr_1) == QuestionGeneratorIdentity.derive_variant_key(arr_2):
		print("[QGEN-GATE-003] FAIL: Distinct array element ordering collapsed to same variant_key")
		return false

	# Test D: Type Collisions Proof (int vs String vs bool vs float)
	var t_int: String = QuestionGeneratorIdentity.derive_variant_key({"x": 1})
	var t_str: String = QuestionGeneratorIdentity.derive_variant_key({"x": "1"})
	var t_bool: String = QuestionGeneratorIdentity.derive_variant_key({"x": true})
	var t_bstr: String = QuestionGeneratorIdentity.derive_variant_key({"x": "true"})
	var t_flt: String = QuestionGeneratorIdentity.derive_variant_key({"x": 3.0})
	var t_fstr: String = QuestionGeneratorIdentity.derive_variant_key({"x": "3.0"})
	var t_fint: String = QuestionGeneratorIdentity.derive_variant_key({"x": 3})

	if t_int == t_str:
		print("[QGEN-GATE-003] FAIL: int 1 collided with String '1'")
		return false
	if t_bool == t_bstr:
		print("[QGEN-GATE-003] FAIL: bool true collided with String 'true'")
		return false
	if t_flt == t_fstr or t_flt == t_fint:
		print("[QGEN-GATE-003] FAIL: float 3.0 collided with String '3.0' or int 3")
		return false

	# Test E: Delimiter Collision Proof
	var d1: String = QuestionGeneratorIdentity.derive_variant_key({"x": "a:b"})
	var d2: String = QuestionGeneratorIdentity.derive_variant_key({"x:a": "b"})
	if d1 == d2:
		print("[QGEN-GATE-003] FAIL: Delimiter string 'x':'a:b' collided with 'x:a':'b'")
		return false

	var d3: String = QuestionGeneratorIdentity.derive_variant_key({"a": 1, "b": 2})
	var d4: String = QuestionGeneratorIdentity.derive_variant_key({"a": "1,b:2"})
	if d3 == d4:
		print("[QGEN-GATE-003] FAIL: Delimiter string 'a':1,'b':2 collided with 'a':'1,b:2'")
		return false

	# Test F: Stable Derivation Across Repeated Runs
	for i in range(10):
		var repeated_var: String = QuestionGeneratorIdentity.derive_variant_key(tuple_a1)
		var repeated_id: String = QuestionGeneratorIdentity.build_generated_id_from_params("qspec_random_trial_mc", tuple_a1)
		if repeated_var != var_a1 or repeated_id != gen_id_a1:
			print("[QGEN-GATE-003] FAIL: Derivation instability detected across runs")
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

	# Generator Materialization with automatic parameter derivation & signature test
	var gen: RefCounted = QuestionGenerator.new()
	var spec: Dictionary = {
		"spec_id": "qspec_random_trial_mc",
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

	# Public production signature: generate_question(spec, pack, parameters)
	var q1: Dictionary = gen.generate_question(spec, {}, tuple_a1)
	var q2: Dictionary = gen.generate_question(spec, {}, tuple_a2)

	if q1["question_id"] != gen_id_a1 or q2["question_id"] != gen_id_a1:
		print("[QGEN-GATE-003] FAIL: Generator auto-derivation failed: " + String(q1["question_id"]))
		return false

	if q1 != q2:
		print("[QGEN-GATE-003] FAIL: Materialization not deterministic across identical parameter calls")
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
		var q: Dictionary = gen.generate_question(spec, {}, {"k": 4})
		ids.append(String(q["question_id"]))

	var expected_vkey: String = QuestionGeneratorIdentity.derive_variant_key({"k": 4})
	var expected_id: String = "qgen_qspec_coin_flip_" + expected_vkey

	for id_val in ids:
		if id_val != expected_id:
			print("[QGEN-GATE-010] FAIL: ID instability detected: " + id_val + " vs " + expected_id)
			return false

	print("[QGEN-GATE-010] PASS")
	return true

static func test_qgen_011_collision_protection() -> bool:
	print("[QGEN-GATE-011] Testing collision rules & real batch duplicate rejection...")

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

	# 5. Real batch duplicate collision rejection (No silent overwrite)
	var gen: QuestionGenerator = QuestionGenerator.new()
	var spec: Dictionary = {
		"spec_id": "qspec_coin_flip",
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_id": "random_trial",
		"interaction_type": "input",
		"template": {
			"prompt": "Gieo {k} lần, sấp {heads} lần.",
			"explanation": "Exp",
			"learning_objective": "Obj",
			"interaction_payload": {"input_type": "integer", "placeholder_text": "..."},
			"answer_spec": {"accepted_values": [3]}
		}
	}

	# Valid batch (distinct tuples) -> PASS
	var valid_batch_tuples: Array[Dictionary] = [
		{"k": 3, "heads": 2},
		{"k": 3, "heads": 1}
	]
	var valid_result: Dictionary = gen.generate_batch(spec, {}, valid_batch_tuples)
	if not bool(valid_result.get("success", false)):
		print("[QGEN-GATE-011] FAIL: Valid batch failed generation: " + str(valid_result))
		return false

	# Duplicate batch (same params, different order) -> EXPLICIT REJECTION
	var duplicate_batch_tuples: Array[Dictionary] = [
		{"k": 3, "heads": 2},
		{"heads": 2, "k": 3}
	]
	var dup_result: Dictionary = gen.generate_batch(spec, {}, duplicate_batch_tuples)
	if bool(dup_result.get("success", true)):
		print("[QGEN-GATE-011] FAIL: Batch with duplicate parameters was not explicitly rejected!")
		return false
	if dup_result.get("duplicate_id") == "":
		print("[QGEN-GATE-011] FAIL: Batch duplicate result missing duplicate_id field")
		return false

	# Validate batch uniqueness standalone utility test
	var questions_with_dup: Array[Dictionary] = [
		{"question_id": "qgen_qspec_a_v1"},
		{"question_id": "qgen_qspec_b_v1"},
		{"question_id": "qgen_qspec_a_v1"}
	]
	var validate_res: Dictionary = QuestionGeneratorIdentity.validate_batch_uniqueness(questions_with_dup)
	if bool(validate_res.get("success", true)):
		print("[QGEN-GATE-011] FAIL: validate_batch_uniqueness accepted duplicate question_ids")
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
