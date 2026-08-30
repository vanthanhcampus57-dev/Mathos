class_name TestD1ProceduralQGen
extends RefCounted

## Unit & Integration test suite for D1 Procedural Question Generation.
## Covers all 5 D1 subtopics (random_trial, sample_space, event_subset, event_classification, counting_outcomes)
## across all 15 template families and legal interaction types.

const ContentRepository = preload("res://src/content/repositories/content_repository.gd")
const ContentValidator = preload("res://src/content/repositories/content_validator.gd")
const QuestionGeneratorIdentity = preload("res://src/education/question/generator/question_generator_identity.gd")
const D1QuestionGenerator = preload("res://src/education/question/generator/d1_question_generator.gd")
const QuestionEvaluator = preload("res://src/education/question/question_evaluator.gd")

static func run_all_tests() -> bool:
	print("--- RUNNING D1 PROCEDURAL QGEN SUITE ---")
	var all_ok: bool = true

	all_ok = test_d1_qgen_001_content_repository_validation() and all_ok
	all_ok = test_d1_qgen_002_random_trial_templates() and all_ok
	all_ok = test_d1_qgen_003_sample_space_templates() and all_ok
	all_ok = test_d1_qgen_004_event_subset_templates() and all_ok
	all_ok = test_d1_qgen_005_event_classification_templates() and all_ok
	all_ok = test_d1_qgen_006_counting_outcomes_templates() and all_ok
	all_ok = test_d1_qgen_007_determinism_batch_uniqueness() and all_ok

	return all_ok

static func test_d1_qgen_001_content_repository_validation() -> bool:
	print("[D1-QGEN-001] Testing production content repository load & validation for D1 QGen JSON datasets...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://content")

	if not report.publication_allowed:
		print("[D1-QGEN-001] FAIL: Publication not allowed for res://content")
		return false

	var catalog: ValidatedCatalog = repo.get_catalog()
	if catalog == null:
		print("[D1-QGEN-001] FAIL: Published catalog is null")
		return false

	var packs: Array[Dictionary] = catalog.get_all_math_knowledge_packs()
	var specs: Array[Dictionary] = catalog.get_all_question_generation_specs()

	if packs.size() < 5:
		print("[D1-QGEN-001] FAIL: Expected at least 5 MathKnowledgePacks, got: " + str(packs.size()))
		return false

	if specs.size() < 15:
		print("[D1-QGEN-001] FAIL: Expected at least 15 QuestionGenerationSpecs, got: " + str(specs.size()))
		return false

	print("[D1-QGEN-001] PASS (5 MathKnowledgePacks, 15 QuestionGenerationSpecs validated)")
	return true

static func test_d1_qgen_002_random_trial_templates() -> bool:
	print("[D1-QGEN-002] Testing subtopic 'random_trial' templates (qspec_d1_rt_01, 02, 03)...")
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://content")
	var catalog: ValidatedCatalog = repo.get_catalog()
	var gen: D1QuestionGenerator = D1QuestionGenerator.new()

	# 1. qspec_d1_rt_01 (MC)
	var spec_rt01: Dictionary = catalog.get_question_generation_spec("qspec_d1_rt_01")
	var pack_rt: Dictionary = catalog.get_math_knowledge_pack("mkp_d1_random_trial")
	for v in ["v1", "v2", "v3"]:
		var q: Dictionary = gen.generate_question(spec_rt01, pack_rt, {"variant": v})
		if not _is_valid_generated_q(q, "qspec_d1_rt_01"):
			print("[D1-QGEN-002] FAIL: Invalid generated question for qspec_d1_rt_01 variant " + v)
			return false
		if q["answer_spec"]["correct_option_id"] != "opt_a":
			print("[D1-QGEN-002] FAIL: Incorrect answer_spec for qspec_d1_rt_01")
			return false

	# 2. qspec_d1_rt_02 (Matching)
	var spec_rt02: Dictionary = catalog.get_question_generation_spec("qspec_d1_rt_02")
	for v in ["v1", "v2"]:
		var q: Dictionary = gen.generate_question(spec_rt02, pack_rt, {"variant": v})
		if not _is_valid_generated_q(q, "qspec_d1_rt_02"):
			print("[D1-QGEN-002] FAIL: Invalid generated question for qspec_d1_rt_02 variant " + v)
			return false

	# 3. qspec_d1_rt_03 (DragDrop)
	var spec_rt03: Dictionary = catalog.get_question_generation_spec("qspec_d1_rt_03")
	var q_rt03: Dictionary = gen.generate_question(spec_rt03, pack_rt, {"variant": "v1"})
	if not _is_valid_generated_q(q_rt03, "qspec_d1_rt_03"):
		print("[D1-QGEN-002] FAIL: Invalid generated question for qspec_d1_rt_03")
		return false

	print("[D1-QGEN-002] PASS")
	return true

static func test_d1_qgen_003_sample_space_templates() -> bool:
	print("[D1-QGEN-003] Testing subtopic 'sample_space' templates (qspec_d1_ss_01, 02, 03)...")
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://content")
	var catalog: ValidatedCatalog = repo.get_catalog()
	var gen: D1QuestionGenerator = D1QuestionGenerator.new()
	var pack_ss: Dictionary = catalog.get_math_knowledge_pack("mkp_d1_sample_space")

	# 1. qspec_d1_ss_01 (MC)
	var spec_ss01: Dictionary = catalog.get_question_generation_spec("qspec_d1_ss_01")
	for faces in [4, 6, 8]:
		var q: Dictionary = gen.generate_question(spec_ss01, pack_ss, {"faces": faces})
		if not _is_valid_generated_q(q, "qspec_d1_ss_01"):
			print("[D1-QGEN-003] FAIL: Invalid question for qspec_d1_ss_01 faces=" + str(faces))
			return false

	# 2. qspec_d1_ss_02 (Input 2^k)
	var spec_ss02: Dictionary = catalog.get_question_generation_spec("qspec_d1_ss_02")
	var expected_ss02: Dictionary = {1: 2, 2: 4, 3: 8}
	for k in [1, 2, 3]:
		var q: Dictionary = gen.generate_question(spec_ss02, pack_ss, {"k": k})
		if not _is_valid_generated_q(q, "qspec_d1_ss_02"):
			print("[D1-QGEN-003] FAIL: Invalid question for qspec_d1_ss_02 k=" + str(k))
			return false
		var accepted: Array = q["answer_spec"]["accepted_values"]
		if int(accepted[0]) != expected_ss02[k]:
			print("[D1-QGEN-003] FAIL: Answer mismatch for k=" + str(k) + ": expected " + str(expected_ss02[k]) + ", got " + str(accepted[0]))
			return false

	# 3. qspec_d1_ss_03 (Matching)
	var spec_ss03: Dictionary = catalog.get_question_generation_spec("qspec_d1_ss_03")
	var q_ss03: Dictionary = gen.generate_question(spec_ss03, pack_ss, {"variant": "v1"})
	if not _is_valid_generated_q(q_ss03, "qspec_d1_ss_03"):
		print("[D1-QGEN-003] FAIL: Invalid question for qspec_d1_ss_03")
		return false

	print("[D1-QGEN-003] PASS")
	return true

static func test_d1_qgen_004_event_subset_templates() -> bool:
	print("[D1-QGEN-004] Testing subtopic 'event_subset' templates (qspec_d1_es_01, 02, 03)...")
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://content")
	var catalog: ValidatedCatalog = repo.get_catalog()
	var gen: D1QuestionGenerator = D1QuestionGenerator.new()
	var pack_es: Dictionary = catalog.get_math_knowledge_pack("mkp_d1_event_subset")

	# 1. qspec_d1_es_01 (MC)
	var spec_es01: Dictionary = catalog.get_question_generation_spec("qspec_d1_es_01")
	for etype in ["odd", "even", "prime"]:
		var q: Dictionary = gen.generate_question(spec_es01, pack_es, {"event_type": etype})
		if not _is_valid_generated_q(q, "qspec_d1_es_01"):
			print("[D1-QGEN-004] FAIL: Invalid question for qspec_d1_es_01 etype=" + etype)
			return false

	# 2. qspec_d1_es_02 (Input 6 - k)
	var spec_es02: Dictionary = catalog.get_question_generation_spec("qspec_d1_es_02")
	for k in [2, 3, 4, 5]:
		var q: Dictionary = gen.generate_question(spec_es02, pack_es, {"k": k})
		if not _is_valid_generated_q(q, "qspec_d1_es_02"):
			print("[D1-QGEN-004] FAIL: Invalid question for qspec_d1_es_02 k=" + str(k))
			return false
		var accepted: Array = q["answer_spec"]["accepted_values"]
		if int(accepted[0]) != (6 - k):
			print("[D1-QGEN-004] FAIL: Answer mismatch for k=" + str(k) + ": expected " + str(6 - k) + ", got " + str(accepted[0]))
			return false

	# 3. qspec_d1_es_03 (DragDrop)
	var spec_es03: Dictionary = catalog.get_question_generation_spec("qspec_d1_es_03")
	var q_es03: Dictionary = gen.generate_question(spec_es03, pack_es, {"N": 10, "m": 3})
	if not _is_valid_generated_q(q_es03, "qspec_d1_es_03"):
		print("[D1-QGEN-004] FAIL: Invalid question for qspec_d1_es_03")
		return false

	print("[D1-QGEN-004] PASS")
	return true

static func test_d1_qgen_005_event_classification_templates() -> bool:
	print("[D1-QGEN-005] Testing subtopic 'event_classification' templates (qspec_d1_ec_01, 02, 03)...")
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://content")
	var catalog: ValidatedCatalog = repo.get_catalog()
	var gen: D1QuestionGenerator = D1QuestionGenerator.new()
	var pack_ec: Dictionary = catalog.get_math_knowledge_pack("mkp_d1_event_classification")

	# 1. qspec_d1_ec_01 (Matching)
	var spec_ec01: Dictionary = catalog.get_question_generation_spec("qspec_d1_ec_01")
	var q_ec01: Dictionary = gen.generate_question(spec_ec01, pack_ec, {"variant": "v1"})
	if not _is_valid_generated_q(q_ec01, "qspec_d1_ec_01"):
		print("[D1-QGEN-005] FAIL: Invalid question for qspec_d1_ec_01")
		return false

	# 2. qspec_d1_ec_02 (MC impossible event)
	var spec_ec02: Dictionary = catalog.get_question_generation_spec("qspec_d1_ec_02")
	for v in ["v1", "v2"]:
		var q: Dictionary = gen.generate_question(spec_ec02, pack_ec, {"variant": v})
		if not _is_valid_generated_q(q, "qspec_d1_ec_02"):
			print("[D1-QGEN-005] FAIL: Invalid question for qspec_d1_ec_02 variant " + v)
			return false

	# 3. qspec_d1_ec_03 (DragDrop)
	var spec_ec03: Dictionary = catalog.get_question_generation_spec("qspec_d1_ec_03")
	var q_ec03: Dictionary = gen.generate_question(spec_ec03, pack_ec, {"variant": "v1"})
	if not _is_valid_generated_q(q_ec03, "qspec_d1_ec_03"):
		print("[D1-QGEN-005] FAIL: Invalid question for qspec_d1_ec_03")
		return false

	print("[D1-QGEN-005] PASS")
	return true

static func test_d1_qgen_006_counting_outcomes_templates() -> bool:
	print("[D1-QGEN-006] Testing subtopic 'counting_outcomes' templates (qspec_d1_co_01, 02, 03)...")
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://content")
	var catalog: ValidatedCatalog = repo.get_catalog()
	var gen: D1QuestionGenerator = D1QuestionGenerator.new()
	var pack_co: Dictionary = catalog.get_math_knowledge_pack("mkp_d1_counting_outcomes")

	# 1. qspec_d1_co_01 (Input 2-dice sum S in {3..11})
	var spec_co01: Dictionary = catalog.get_question_generation_spec("qspec_d1_co_01")
	var expected_dice_sums: Dictionary = {
		3: 2, 4: 3, 5: 4, 6: 5, 7: 6, 8: 5, 9: 4, 10: 3, 11: 2
	}
	for S in expected_dice_sums.keys():
		var q: Dictionary = gen.generate_question(spec_co01, pack_co, {"S": S})
		if not _is_valid_generated_q(q, "qspec_d1_co_01"):
			print("[D1-QGEN-006] FAIL: Invalid question for qspec_d1_co_01 S=" + str(S))
			return false
		var accepted: Array = q["answer_spec"]["accepted_values"]
		if int(accepted[0]) != expected_dice_sums[S]:
			print("[D1-QGEN-006] FAIL: Dice sum S=" + str(S) + " expected " + str(expected_dice_sums[S]) + ", got " + str(accepted[0]))
			return false

	# 2. qspec_d1_co_02 (Input 3-coin at least k heads)
	var spec_co02: Dictionary = catalog.get_question_generation_spec("qspec_d1_co_02")
	var expected_coin_heads: Dictionary = {2: 4, 3: 1}
	for k in [2, 3]:
		var q: Dictionary = gen.generate_question(spec_co02, pack_co, {"k": k})
		if not _is_valid_generated_q(q, "qspec_d1_co_02"):
			print("[D1-QGEN-006] FAIL: Invalid question for qspec_d1_co_02 k=" + str(k))
			return false
		var accepted: Array = q["answer_spec"]["accepted_values"]
		if int(accepted[0]) != expected_coin_heads[k]:
			print("[D1-QGEN-006] FAIL: Coin heads k=" + str(k) + " expected " + str(expected_coin_heads[k]) + ", got " + str(accepted[0]))
			return false

	# 3. qspec_d1_co_03 (Matching urn 2-ball draw without replacement)
	var spec_co03: Dictionary = catalog.get_question_generation_spec("qspec_d1_co_03")
	for setup in ["urn_setup_1", "urn_setup_2"]:
		var q: Dictionary = gen.generate_question(spec_co03, pack_co, {"setup": setup})
		if not _is_valid_generated_q(q, "qspec_d1_co_03"):
			print("[D1-QGEN-006] FAIL: Invalid question for qspec_d1_co_03 setup=" + setup)
			return false

	print("[D1-QGEN-006] PASS")
	return true

static func test_d1_qgen_007_determinism_batch_uniqueness() -> bool:
	print("[D1-QGEN-007] Testing determinism, batch generation, and question_id uniqueness...")
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://content")
	var catalog: ValidatedCatalog = repo.get_catalog()
	var gen: D1QuestionGenerator = D1QuestionGenerator.new()
	var spec_co01: Dictionary = catalog.get_question_generation_spec("qspec_d1_co_01")
	var pack_co: Dictionary = catalog.get_math_knowledge_pack("mkp_d1_counting_outcomes")

	# Deterministic repeatability test
	var q1: Dictionary = gen.generate_question(spec_co01, pack_co, {"S": 5})
	var q2: Dictionary = gen.generate_question(spec_co01, pack_co, {"S": 5})
	if q1 != q2:
		print("[D1-QGEN-007] FAIL: Repeated generation with same parameters produced non-identical output")
		return false

	# Batch generation across 9 distinct parameter tuples
	var batch_tuples: Array[Dictionary] = [
		{"S": 3}, {"S": 4}, {"S": 5}, {"S": 6}, {"S": 7}, {"S": 8}, {"S": 9}, {"S": 10}, {"S": 11}
	]
	var batch_res: Dictionary = gen.generate_batch(spec_co01, pack_co, batch_tuples)
	if not bool(batch_res.get("success", false)):
		print("[D1-QGEN-007] FAIL: Batch generation failed: " + str(batch_res))
		return false

	var questions: Array = batch_res.get("questions", []) as Array
	if questions.size() != 9:
		print("[D1-QGEN-007] FAIL: Expected 9 batch questions, got: " + str(questions.size()))
		return false

	var seen_ids: Dictionary = {}
	for q_var in questions:
		var q: Dictionary = q_var as Dictionary
		var q_id: String = String(q.get("question_id", ""))
		if not QuestionGeneratorIdentity.is_generated_id(q_id):
			print("[D1-QGEN-007] FAIL: Generated question ID lacks 'qgen_' prefix: " + q_id)
			return false
		if seen_ids.has(q_id):
			print("[D1-QGEN-007] FAIL: Duplicate question_id detected in batch: " + q_id)
			return false
		seen_ids[q_id] = true

	# QuestionEvaluator payload contract check with exact {"value": "4"} shape
	var spec_ss02: Dictionary = catalog.get_question_generation_spec("qspec_d1_ss_02")
	var pack_ss: Dictionary = catalog.get_math_knowledge_pack("mkp_d1_sample_space")
	var q_eval: Dictionary = gen.generate_question(spec_ss02, pack_ss, {"k": 2})
	var eval_res: Dictionary = QuestionEvaluator.evaluate(
		q_eval,
		{"value": "4"},
		"stage_01_01",
		"practice",
		5.0,
		{"PERFECT": 10.0, "GREAT": 20.0, "GOOD": 30.0, "PASS": 45.0},
		"attempt_d1_001"
	)
	if not bool(eval_res.get("success", false)) or not bool((eval_res.get("result", {}) as Dictionary).get("is_correct", false)):
		print("[D1-QGEN-007] FAIL: QuestionEvaluator failed for payload {'value': '4'}: " + str(eval_res))
		return false

	print("[D1-QGEN-007] PASS (Deterministic repeatability, 9-item batch uniqueness & QuestionEvaluator contract verified)")
	return true

static func _is_valid_generated_q(q: Dictionary, expected_spec_id: String) -> bool:
	var q_id: String = String(q.get("question_id", ""))
	if not QuestionGeneratorIdentity.is_generated_id(q_id):
		return false
	var parsed: Dictionary = QuestionGeneratorIdentity.parse_generated_id(q_id)
	if not bool(parsed.get("success", false)):
		return false
	if parsed.get("spec_id") != expected_spec_id:
		return false
	if String(q.get("prompt", "")).is_empty():
		return false
	if String(q.get("explanation", "")).is_empty():
		return false
	if not (q.get("interaction_payload") is Dictionary) or not (q.get("answer_spec") is Dictionary):
		return false
	return true
