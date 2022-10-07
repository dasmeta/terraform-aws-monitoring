/**
 * # Example Setup
 * ```tf
 * module "basic-dashboard-with-text" {
 *   source = "../../"
 *   name   = "Basic-Dashboard-with-text"
 *   rows = [
 *     [
 *       {
 *         type : "text/title"
 *         text : "Row 1 / col 1"
 *       }
 *     ],
 *     [
 *       {
 *         type : "text/title"
 *         text : "Row 2 / col 1"
 *       }
 *     ]
 *   ]
 * }
 */
