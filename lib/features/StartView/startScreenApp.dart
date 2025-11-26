import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studentApp/features/repository/models/startscreen_model.dart';
import '../repository/models/schedule_model.dart';
 // правильный импорт

class Startscreenapp extends StatefulWidget {
  const Startscreenapp({super.key});

  @override
  State<Startscreenapp> createState() => _StartscreenappState();
}

class _StartscreenappState extends State<Startscreenapp> {
  bool _downloading = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(),
      home: ChangeNotifierProvider<StartscreenModel>(
        create: (context) {
          final model = StartscreenModel();
          model.loadEducationForms(); // Загружаем здесь асинхронно
          return model;
        },
        child: SafeArea(
          child: Scaffold(
            body: Consumer<StartscreenModel>(
              builder: (context, model, child) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: model.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : model.errorMessage != null
                          ? Center(child: Text(model.errorMessage!))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Добро пожаловать!\nДавайте все настроим по вашему вкусу',
                                  style: TextStyle(fontSize: 30, 
                                  fontWeight: FontWeight.bold, ),
                                ),
                                const SizedBox(height: 30),

                                // Форма обучения
                                DropdownButtonFormField<EducationForm>(
                                  value: model.selectedForm,
                                  decoration: const InputDecoration(
                                    labelText: 'Форма обучения',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: model.educationForms.map((EducationForm form) {
                                    return DropdownMenuItem<EducationForm>(
                                      value: form,
                                      child: Text(form.name),
                                    );
                                  }).toList(),
                                  onChanged: (EducationForm? newValue) {
                                    model.selectForm(newValue);
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Курс
                                DropdownButtonFormField<Course>(
                                  value: model.selectedCourse,
                                  decoration: const InputDecoration(
                                    labelText: 'Курс',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: model.getCoursesForSelectedForm().map((Course course) {
                                    return DropdownMenuItem<Course>(
                                      value: course,
                                      child: Text('${course.number} курс'),
                                    );
                                  }).toList(),
                                  onChanged: model.selectedForm != null
                                      ? (Course? newValue) {
                                          model.selectCourse(newValue);
                                        }
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                // Группа
                                DropdownButtonFormField<Group>(
                                  value: model.selectedGroup,
                                  decoration: const InputDecoration(
                                    labelText: 'Группа',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: model.getGroupsForSelectedCourse().map((Group group) {
                                    return DropdownMenuItem<Group>(
                                      value: group,
                                      child: Text(group.name),
                                    );
                                  }).toList(),
                                  onChanged: model.selectedCourse != null
                                      ? (Group? newValue) async {
                                          model.selectGroup(newValue);
                                          if (newValue != null) {
                                            setState(() => _downloading = true);
                                            try {
                                              final schedule = await model.downloadSchedule();
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Расписание для ${newValue.name} скачано! (${schedule.length} месяцев)'),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Ошибка скачивания: $e')),
                                                );
                                              }
                                            } finally {
                                              setState(() => _downloading = false);
                                            }
                                          }
                                        }
                                      : null,
                                ),
                              Padding(
                                padding: ElevatedButton(
                                  onPressed: null, 
                                  child: Text('Нажмите чтобы продолжить'))),
                               

                                if (_downloading) const Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                              ],
                            ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}