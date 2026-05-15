import 'package:auto_route/auto_route.dart';

final appRouter = AppRouter();

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType =>
      RouteType.material(); //.cupertino, .adaptive ..etc

  @override
  List<AutoRoute> get routes => [
        // HomeScreen is generated as HomeRoute because
        // of the replaceInRouteName property


      ];
  @override
  List<AutoRouteGuard> get guards => [
        // optionally add root guards here
      ];
}
