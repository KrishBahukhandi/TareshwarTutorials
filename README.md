# Tareshwar Tutorials - EduTech Platform

A modern, full-featured educational technology platform built with Flutter and Supabase. This platform provides comprehensive learning management capabilities for administrators, teachers, and students.

## 🌟 Features

### Admin Dashboard
- **Modern UI** with persistent sidebar navigation
- **Real-time Statistics** - Track students, teachers, courses, batches, and enrollments
- **User Management**
  - Create, view, activate/deactivate, and delete teachers
  - Create, view, and delete students
- **Course Management** - Create and manage courses
- **Batch Management** - Create and schedule batches with seat limits
- **Responsive Design** - Works on desktop, tablet, and mobile

### Teacher Portal
- Manage assigned batches
- Upload and organize course content
- Upload video lectures and study materials
- Track student progress

### Student Portal
- Browse and enroll in courses
- Access video lectures
- Download study materials and notes
- Track learning progress

## 🚀 Tech Stack

- **Frontend**: Flutter (Cross-platform - Web, iOS, Android, Desktop)
- **Backend**: Supabase (PostgreSQL database, Authentication, Storage)
- **State Management**: Riverpod
- **Routing**: GoRouter
- **UI**: Material Design 3

## 📋 Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Supabase account
- Node.js (for database scripts)

## 🛠️ Installation

### 1. Clone the repository
```bash
git clone https://github.com/KrishBahukhandi/TareshwarTutorials.git
cd TareshwarTutorials
```

### 2. Install dependencies
```bash
flutter pub get
npm install
```

### 3. Set up environment variables
Create a `.env` file in the root directory (use `.env.example` as template):
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

ADMIN_EMAIL=admin@edutech.test
ADMIN_PASSWORD=your_admin_password

TEACHER_EMAIL=teacher@edutech.test
TEACHER_PASSWORD=your_teacher_password

STUDENT_EMAIL=student@edutech.test
STUDENT_PASSWORD=your_student_password
```

### 4. Set up Supabase database
Run the database setup script:
```bash
# In Supabase SQL Editor, run:
# 1. scripts/setup_database.sql
# 2. scripts/recreate_policies.sql
```

### 5. Run the app
```bash
# For web
flutter run -d chrome --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key

# For mobile (with device connected)
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

## 📱 Platform Support

- ✅ Web
- ✅ iOS
- ✅ Android
- ✅ macOS
- ✅ Windows
- ✅ Linux

## 🗂️ Project Structure

```
lib/
├── admin/              # Admin dashboard screens
│   ├── batches/       # Batch management
│   ├── students/      # Student management
│   ├── teachers/      # Teacher management
│   └── widgets/       # Reusable admin widgets
├── auth/              # Authentication screens
├── core/              # Core utilities and constants
│   ├── constants/     # App-wide constants
│   ├── theme/         # Theme configuration
│   └── utils/         # Data models
├── providers/         # Riverpod state providers
├── router/            # Navigation/routing
├── services/          # Business logic & API calls
├── student/           # Student portal screens
└── teacher/           # Teacher portal screens
```

## 🔐 Default Credentials

After running setup scripts:
- **Admin**: admin@edutech.test / ChangeMe123!
- **Teacher**: teacher@edutech.test / ChangeMe123!
- **Student**: student@edutech.test / ChangeMe123!

**⚠️ Change these passwords in production!**

## 📸 Screenshots

### Desktop - Admin Dashboard
Modern admin interface with sidebar navigation and real-time statistics.

### Mobile - Responsive Design
Drawer navigation with adaptive layouts for phones and tablets.

## 🛣️ Roadmap

- [ ] Advanced analytics and reporting
- [ ] Real-time notifications
- [ ] Chat/messaging system
- [ ] Assignment submission and grading
- [ ] Quiz and assessment system
- [ ] Certificate generation
- [ ] Payment integration
- [ ] Mobile app optimization

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

**Krish Bahukhandi**
- GitHub: [@KrishBahukhandi](https://github.com/KrishBahukhandi)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for backend infrastructure
- Material Design for UI guidelines

---

**Built with ❤️ using Flutter and Supabase**
