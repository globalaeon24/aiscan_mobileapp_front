import '../models/dashboard_document.dart';

class DemoDashboardData {
  const DemoDashboardData._();

  static const userName = 'Адильжан';
  static const userInitials = 'AB';
  static const totalDocuments = 24;
  static const averageOriginality = 85;
  static const completedWorks = 18;

  static const documents = [
    DashboardDocument(
      title: 'Курсовая',
      subtitle: 'Ерлан Б.',
      originalityPercent: 75,
      aiPercent: 5,
      statusType: DocumentStatusType.success,
    ),
    DashboardDocument(
      title: 'Диплом v3.pdf',
      subtitle: 'Медетбек А. · 13.05',
      statusText: 'Обработка',
      statusType: DocumentStatusType.processing,
    ),
    DashboardDocument(
      title: 'Эссе.docx',
      subtitle: 'Асылжанов А. 13.05',
      statusText: 'Ошибка',
      statusType: DocumentStatusType.error,
    ),
    DashboardDocument(
      title: 'Курсовая работа.docx',
      subtitle: 'Аужатов И. · 14.05',
      originalityPercent: 75,
      statusType: DocumentStatusType.success,
    ),
  ];
}
