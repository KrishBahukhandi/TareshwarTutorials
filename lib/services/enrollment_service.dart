import '../core/utils/app_user.dart';
import '../core/utils/batch.dart';
import '../core/utils/enrollment.dart';
import 'audit_service.dart';
import 'batch_service.dart';
import 'student_service.dart';
import 'supabase_client.dart';

/// Enrollment with student and batch details
class EnrollmentWithDetails {
  final Enrollment enrollment;
  final AppUser student;
  final Batch batch;

  const EnrollmentWithDetails({
    required this.enrollment,
    required this.student,
    required this.batch,
  });
}

class EnrollmentService {
  final AuditService _auditService = AuditService();

  /// Enroll a student in a batch (with seat validation)
  Future<void> enroll({
    required String studentId,
    required String batchId,
  }) async {
    // Check if student already enrolled
    final existing = await supabase
        .from('enrollments')
        .select()
        .eq('student_id', studentId)
        .eq('batch_id', batchId)
        .eq('is_active', true)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Student is already enrolled in this batch');
    }

    // Check seat availability (database trigger will also validate)
    final batch = await supabase
        .from('batches')
        .select()
        .eq('id', batchId)
        .single();

    final enrollmentCount = await _getActiveEnrollmentCount(batchId);
    final seatLimit = batch['seat_limit'] as int;

    if (enrollmentCount >= seatLimit) {
      throw Exception('Batch is full ($enrollmentCount/$seatLimit)');
    }

    // Enroll student
    await supabase.from('enrollments').insert({
      'student_id': studentId,
      'batch_id': batchId,
      'is_active': true,
    });

    // Log action
    final student = await StudentService().fetchStudentById(studentId);
    await _auditService.logAction(
      action: 'enroll',
      resourceType: 'enrollment',
      resourceId: '$studentId-$batchId',
      resourceName: student?.name ?? 'Unknown Student',
      newData: {'student_id': studentId, 'batch_id': batchId},
    );
  }

  /// Remove student from batch (soft delete)
  Future<void> unenroll({
    required String studentId,
    required String batchId,
  }) async {
    final enrollment = await supabase
        .from('enrollments')
        .select()
        .eq('student_id', studentId)
        .eq('batch_id', batchId)
        .eq('is_active', true)
        .maybeSingle();

    if (enrollment == null) {
      throw Exception('Enrollment not found');
    }

    // Soft delete
    await supabase
        .from('enrollments')
        .update({
          'is_active': false,
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', enrollment['id']);

    // Log action
    final student = await StudentService().fetchStudentById(studentId);
    await _auditService.logAction(
      action: 'unenroll',
      resourceType: 'enrollment',
      resourceId: enrollment['id'],
      resourceName: student?.name ?? 'Unknown Student',
      oldData: enrollment,
    );
  }

  /// Move student from one batch to another
  Future<void> moveStudentBatch({
    required String studentId,
    required String fromBatchId,
    required String toBatchId,
  }) async {
    // Validate new batch has space
    final toBatch = await supabase
        .from('batches')
        .select()
        .eq('id', toBatchId)
        .single();

    final enrollmentCount = await _getActiveEnrollmentCount(toBatchId);
    final seatLimit = toBatch['seat_limit'] as int;

    if (enrollmentCount >= seatLimit) {
      throw Exception('Target batch is full');
    }

    // Remove from old batch
    await unenroll(studentId: studentId, batchId: fromBatchId);

    // Enroll in new batch
    await enroll(studentId: studentId, batchId: toBatchId);

    // Log action
    final student = await StudentService().fetchStudentById(studentId);
    await _auditService.logAction(
      action: 'update',
      resourceType: 'enrollment',
      resourceId: studentId,
      resourceName: '${student?.name ?? "Student"} moved batches',
      oldData: {'batch_id': fromBatchId},
      newData: {'batch_id': toBatchId},
    );
  }

  /// Get all enrollments for a student
  Future<List<Enrollment>> fetchEnrollmentsForStudent(String studentId) async {
    final data = await supabase
        .from('enrollments')
        .select()
        .eq('student_id', studentId)
        .eq('is_active', true)
        .order('enrolled_at', ascending: false);
    return data.map<Enrollment>((row) => Enrollment.fromMap(row)).toList();
  }

  /// Get all enrollments for a batch with student details
  Future<List<EnrollmentWithDetails>> fetchEnrollmentsForBatch(
      String batchId) async {
    final enrollments = await supabase
        .from('enrollments')
        .select()
        .eq('batch_id', batchId)
        .eq('is_active', true)
        .order('enrolled_at', ascending: false);

    final List<EnrollmentWithDetails> result = [];

    for (final enrollmentData in enrollments) {
      final enrollment = Enrollment.fromMap(enrollmentData);
      final student =
          await StudentService().fetchStudentById(enrollment.studentId);
      final batch = await BatchService()
          .fetchAllBatches()
          .then((batches) => batches.firstWhere((b) => b.id == batchId));

      if (student != null) {
        result.add(EnrollmentWithDetails(
          enrollment: enrollment,
          student: student,
          batch: batch,
        ));
      }
    }

    return result;
  }

  /// Get all active enrollments
  Future<List<Enrollment>> fetchAll() async {
    final data = await supabase
        .from('enrollments')
        .select()
        .eq('is_active', true)
        .order('enrolled_at', ascending: false);
    return data.map<Enrollment>((row) => Enrollment.fromMap(row)).toList();
  }

  /// Get batch enrollment statistics
  Future<Map<String, dynamic>> getBatchStats(String batchId) async {
    final batch = await supabase
        .from('batches')
        .select()
        .eq('id', batchId)
        .single();

    final enrolledCount = await _getActiveEnrollmentCount(batchId);
    final seatLimit = batch['seat_limit'] as int;

    return {
      'batch_id': batchId,
      'seat_limit': seatLimit,
      'enrolled_count': enrolledCount,
      'available_seats': seatLimit - enrolledCount,
      'is_full': enrolledCount >= seatLimit,
      'occupancy_percentage': (enrolledCount / seatLimit * 100).round(),
    };
  }

  /// Check if student is enrolled in a batch
  Future<bool> isEnrolled({
    required String studentId,
    required String batchId,
  }) async {
    final enrollment = await supabase
        .from('enrollments')
        .select()
        .eq('student_id', studentId)
        .eq('batch_id', batchId)
        .eq('is_active', true)
        .maybeSingle();

    return enrollment != null;
  }

  /// Get unenrolled students for a batch
  Future<List<AppUser>> getUnenrolledStudents(String batchId) async {
    // Get all enrolled student IDs
    final enrolledIds = await supabase
        .from('enrollments')
        .select('student_id')
        .eq('batch_id', batchId)
        .eq('is_active', true);

    final enrolledStudentIds =
        enrolledIds.map((e) => e['student_id'] as String).toList();

    // Get all active students
    final allStudents = await StudentService().fetchAllStudents();

    // Filter out enrolled students
    return allStudents
        .where((student) => !enrolledStudentIds.contains(student.id))
        .toList();
  }

  /// Private helper to get active enrollment count
  Future<int> _getActiveEnrollmentCount(String batchId) async {
    final enrollments = await supabase
        .from('enrollments')
        .select('id')
        .eq('batch_id', batchId)
        .eq('is_active', true);

    return enrollments.length;
  }
}
