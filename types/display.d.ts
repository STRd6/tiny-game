import { Behavior, Entity, System, SystemConstructor } from "./core"
import * as PIXI from "pixi.js"

export interface DisplaySystemConstructor extends SystemConstructor<DisplaySystem> { }

export interface DisplaySystem extends System {

}

export type DisplayBehavior = DisplayComponentBehavior | DisplayObjectBehavior

export interface Camera {
  entityMap: Map<number, DisplayObject>
  viewport: PIXI.Container
}

export interface DisplayObject extends PIXI.Container {
  EID: number
  entity: Entity
}

export interface DisplayComponent extends DisplayObject {
  name: string
}

export interface DisplayComponentBehavior extends Behavior {
  type: "component"
  name: string
  display(e: Entity): DisplayComponent
}

export interface DisplayObjectBehavior extends Behavior {
  type: "object"
  display(e: Entity): DisplayObject
}

export interface CameraBehavior extends Behavior {
  display(e: Entity): Camera
}
