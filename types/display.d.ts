import { Behavior, Entity, GameInstance, System, SystemConstructor } from "./core"
import * as PIXI from "pixi.js"

export interface DisplaySystemConstructor extends SystemConstructor<DisplaySystem> { }

export interface DisplaySystem extends System {
  name: "display"
  app: PIXI.Application
  camera: {
    create(e: Entity, behavior: DisplayCameraBehavior): void
    render(e: Entity, behavior: DisplayCameraBehavior): void
    destroy(e: Entity, behavior: DisplayCameraBehavior): void
  }

  component: {
    create(e: Entity, behavior: DisplayComponentBehavior, name: string): void
    render(e: Entity, behavior: DisplayComponentBehavior, name: string): void
    destroy(e: Entity, behavior: DisplayComponent, name: string): void
  }

  hud: {
    create(e: Entity, behavior: DisplayHudBehavior, name: string): void
    render(e: Entity, behavior: DisplayHudBehavior, name: string): void
    destroy(e: Entity, behavior: DisplayHudBehavior, name: string): void
  }

  object: {
    create(e: Entity, behavior: DisplayObjectBehavior): void
    render(e: Entity, behavior: DisplayObjectBehavior): void
    destroy(e: Entity, behavior: DisplayObjectBehavior): void
  }

  behaviorsAdded(game: GameInstance): void
  fullscreenHandler(e: KeyboardEvent): void
  updateEntity(): void
  render(game: GameInstance): void
}

export type DisplayBehavior =
  DisplayCameraBehavior |
  DisplayComponentBehavior |
  DisplayHudBehavior |
  DisplayObjectBehavior

export interface Camera extends PIXI.Container {
  entity: Entity
  entityMap: Map<number, DisplayObject>
  viewport: PIXI.Container

  destroy(options?: { children: boolean }): void
}

export interface DisplayObject extends PIXI.Container {
  EID: Entity["ID"]
  entity: Entity
}

export interface DisplayComponent extends DisplayObject {
  name: string
}

export interface DisplayHUD {
  EID: Entity["ID"]

  destroy(options?: { children: boolean }): void
}

export interface DisplayComponentBehavior extends Behavior {
  type: "component"
  name: string
  display(e: Entity): DisplayComponent
  render(e: Entity, camera: Camera): void
}

export interface DisplayObjectBehavior extends Behavior {
  type: "object"
  name: undefined
  display(e: Entity): DisplayObject
  render(e: Entity, displayObject: DisplayObject): void
}

export interface DisplayCameraBehavior extends Behavior {
  type: "camera"
  name: undefined
  display(e: Entity): Camera
  render(e: Entity, camera: Camera): void
}

export interface DisplayHudBehavior extends Behavior {
  type: "hud"
  name: undefined
  display(e: Entity): DisplayHUD
  render(e: Entity, hud: DisplayHUD): void
}
