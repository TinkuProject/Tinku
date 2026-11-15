import { RouteDirection } from "../constants/enums.constants";

export interface TransportRoute {
  id: number;
  transport_line_id: number;
  direction: RouteDirection;
  stop_order: number;

  location: {
    latitude: number;
    longitude: number;
  };
}