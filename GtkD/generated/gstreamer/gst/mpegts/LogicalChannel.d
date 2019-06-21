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


module gst.mpegts.LogicalChannel;

private import glib.MemorySlice;
private import gst.mpegts.c.functions;
public  import gst.mpegts.c.types;
private import gtkd.Loader;


/** */
public final class LogicalChannel
{
	/** the main Gtk struct */
	protected GstMpegtsLogicalChannel* gstMpegtsLogicalChannel;
	protected bool ownedRef;

	/** Get the main Gtk struct */
	public GstMpegtsLogicalChannel* getLogicalChannelStruct(bool transferOwnership = false)
	{
		if (transferOwnership)
			ownedRef = false;
		return gstMpegtsLogicalChannel;
	}

	/** the main Gtk struct as a void* */
	protected void* getStruct()
	{
		return cast(void*)gstMpegtsLogicalChannel;
	}

	/**
	 * Sets our main struct and passes it to the parent class.
	 */
	public this (GstMpegtsLogicalChannel* gstMpegtsLogicalChannel, bool ownedRef = false)
	{
		this.gstMpegtsLogicalChannel = gstMpegtsLogicalChannel;
		this.ownedRef = ownedRef;
	}

	~this ()
	{
		if ( Linker.isLoaded(LIBRARY_GSTMPEGTS) && ownedRef )
			sliceFree(gstMpegtsLogicalChannel);
	}


	/** */
	public @property ushort serviceId()
	{
		return gstMpegtsLogicalChannel.serviceId;
	}

	/** Ditto */
	public @property void serviceId(ushort value)
	{
		gstMpegtsLogicalChannel.serviceId = value;
	}

	/** */
	public @property bool visibleService()
	{
		return gstMpegtsLogicalChannel.visibleService != 0;
	}

	/** Ditto */
	public @property void visibleService(bool value)
	{
		gstMpegtsLogicalChannel.visibleService = value;
	}

	/** */
	public @property ushort logicalChannelNumber()
	{
		return gstMpegtsLogicalChannel.logicalChannelNumber;
	}

	/** Ditto */
	public @property void logicalChannelNumber(ushort value)
	{
		gstMpegtsLogicalChannel.logicalChannelNumber = value;
	}

	/** */
	public static GType getType()
	{
		return gst_mpegts_logical_channel_get_type();
	}
}
