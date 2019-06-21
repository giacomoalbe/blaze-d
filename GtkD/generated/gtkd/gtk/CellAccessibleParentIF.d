/*
 * This file is part of gtkD.
 *
 * gtkD is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 3
 * of the License, or (at your option) any later version, with
 * some exceptions, please read the COPYING file.
 *
 * gtkD is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with gtkD; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
 */

// generated automatically - do not change
// find conversion definition on APILookup.txt
// implement new conversion functionalities on the wrap.utils pakage


module gtk.CellAccessibleParentIF;

private import atk.RelationSet;
private import glib.PtrArray;
private import gtk.CellAccessible;
private import gtk.c.functions;
public  import gtk.c.types;
public  import gtkc.gtktypes;


/** */
public interface CellAccessibleParentIF{
	/** Get the main Gtk struct */
	public GtkCellAccessibleParent* getCellAccessibleParentStruct(bool transferOwnership = false);

	/** the main Gtk struct as a void* */
	protected void* getStruct();


	/** */
	public static GType getType()
	{
		return gtk_cell_accessible_parent_get_type();
	}

	/** */
	public void activate(CellAccessible cell);

	/** */
	public void edit(CellAccessible cell);

	/** */
	public void expandCollapse(CellAccessible cell);

	/** */
	public void getCellArea(CellAccessible cell, out GdkRectangle cellRect);

	/** */
	public void getCellExtents(CellAccessible cell, out int x, out int y, out int width, out int height, AtkCoordType coordType);

	/** */
	public void getCellPosition(CellAccessible cell, out int row, out int column);

	/** */
	public int getChildIndex(CellAccessible cell);

	/** */
	public PtrArray getColumnHeaderCells(CellAccessible cell);

	/** */
	public GtkCellRendererState getRendererState(CellAccessible cell);

	/** */
	public PtrArray getRowHeaderCells(CellAccessible cell);

	/** */
	public bool grabFocus(CellAccessible cell);

	/** */
	public void updateRelationset(CellAccessible cell, RelationSet relationset);
}
