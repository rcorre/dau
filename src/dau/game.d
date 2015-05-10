/**
  * Main entry point for starting a game.
  *
  * Authors: <a href="https://github.com/rcorre">rcorre</a>
	* License: <a href="http://opensource.org/licenses/MIT">MIT</a>
	* Copyright: Copyright © 2015, rcorre
  */
module dau.game;

import std.algorithm;
import dau.allegro;
import dau.state;
import dau.input;
import dau.system;
import dau.gui.manager;
import dau.graphics;

/// Main game class.
class Game {
  /// Settings used to configure the game.
  struct Settings {
    int fps;             /// Frames-per-second of update/draw loop
    int numAudioSamples; /// Number of audio samples that can play at once

    Display.Settings display; /// Game window and backbuffer configuration
  }

  @property {
    /// Stack of states that manages game flow.
    auto states()    { return _stateStack; }
    /// Access the game window and backbuffer.
    auto display()   { return _display; }
    /// Recieve input events.
    auto input()     { return _inputManager; }
    /// Seconds elapsed between the current frame and the previous frame.
    auto deltaTime() { return _deltaTime; }
  }

  /**
   * Main entry point for starting a game. Loops until stop() is called on the game instance.
   *
   * Params:
   *  firstState = initial state that the game will begin in
   *  settings = configures the game
   */
  static int run(State!Game firstState, Settings settings) {
    int mainFn() {
      allegroInitAll();
      auto game = new Game(firstState, settings);

      while(!game._stopped) {
        bool frameTick = game.processEvents();

        if (frameTick) {
          game.update();
          game.draw();
        }
      }

      return 0;
    }

    return al_run_allegro(&mainFn);
  }

  /// End the main game loop, causing Game.run to return.
  void stop() {
    _stopped = true;
  }

  private:
  ALLEGRO_TIMER*  _timer;
  StateStack!Game _stateStack;
  InputManager    _inputManager;
  Display         _display;
  float           _deltaTime;
  bool            _stopped;

  ALLEGRO_EVENT_QUEUE* _events;

  this(State!Game firstState, Settings settings) {
    _inputManager = new InputManager;
    _stateStack   = new StateStack!Game(this);
    _display      = Display(settings.display);

    _events = al_create_event_queue();
    _timer = al_create_timer(1.0 / settings.fps);

    al_register_event_source(_events, al_get_keyboard_event_source());
    al_register_event_source(_events, al_get_mouse_event_source());
    al_register_event_source(_events, al_get_timer_event_source(_timer));
    al_register_event_source(_events, al_get_joystick_event_source());

    // start fps timer
    al_start_timer(_timer);

    _stateStack.push(firstState);
  }

  void update() {
    static float last_update_time = 0;

    float current_time = al_get_time();
    _deltaTime         = current_time - last_update_time;
    last_update_time   = current_time;

    _inputManager.update();
    _stateStack.run();
  }

  void draw() {
    display.clear();
    display.flip();
  }

  bool processEvents() {
    ALLEGRO_EVENT event;
    al_wait_for_event(_events, &event);
    switch(event.type) {
      case ALLEGRO_EVENT_TIMER:
        if (event.timer.source == _timer) return true;
        break;
      case ALLEGRO_EVENT_DISPLAY_CLOSE:
        stop();
        break;
      case ALLEGRO_EVENT_DISPLAY_RESIZE:
        //al_acknowledge_resize(mainDisplay);
        break;
      default:
    }

    return false;
  }
}
